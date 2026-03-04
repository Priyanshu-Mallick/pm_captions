import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../core/errors/exceptions.dart';
import '../../core/utils/ffmpeg_utils.dart';
import '../../data/datasources/whisper_datasource.dart';
import '../../data/models/caption_model.dart';
import '../../data/models/caption_style_model.dart';
import '../../data/models/word_timestamp_model.dart';
import '../../data/repositories/transcription_repository.dart';

/// The current stage of the processing pipeline.
enum ProcessingState {
  idle,
  extractingAudio,
  transcribing,
  groupingCaptions,
  done,
  error,
}

/// Manages the video processing pipeline: audio extraction → transcription → captioning.
class ProcessingProvider extends ChangeNotifier {
  static final _log = Logger();
  final TranscriptionRepository _transcriptionRepo;

  ProcessingProvider({TranscriptionRepository? transcriptionRepo})
    : _transcriptionRepo = transcriptionRepo ?? TranscriptionRepository();

  // ── State ─────────────────────────────────────────────────────────
  ProcessingState _currentState = ProcessingState.idle;
  double _progress = 0.0;
  String _statusMessage = '';
  String? _errorMessage;
  List<CaptionModel> _captions = [];
  List<WordTimestampModel> _rawWords = [];
  String? _audioPath;
  bool _isCancelled = false;

  // ── Getters ───────────────────────────────────────────────────────
  ProcessingState get currentState => _currentState;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  List<CaptionModel> get captions => _captions;
  List<WordTimestampModel> get rawWords => _rawWords;
  bool get isProcessing =>
      _currentState != ProcessingState.idle &&
      _currentState != ProcessingState.done &&
      _currentState != ProcessingState.error;

  // ── Processing Pipeline ───────────────────────────────────────────

  /// Starts the full processing pipeline.
  Future<void> startProcessing({
    required String videoPath,
    required String apiKey,
    String? language,
    CaptionStyleModel style = const CaptionStyleModel(),
  }) async {
    _isCancelled = false;
    _errorMessage = null;

    try {
      // Save API key
      await WhisperDatasource.saveApiKey(apiKey);

      // Step 1: Extract audio
      _updateState(
        ProcessingState.extractingAudio,
        0.1,
        'Extracting audio from video...',
      );

      if (_isCancelled) return;

      _audioPath = await FFmpegUtils.extractAudio(videoPath);
      _updateState(ProcessingState.extractingAudio, 0.3, 'Audio extracted ✓');

      // Step 2: Transcribe with Whisper
      if (_isCancelled) return;
      _updateState(
        ProcessingState.transcribing,
        0.35,
        'Transcribing speech with Whisper AI...',
      );

      // Start a simulated progress timer to show continuous advancement
      // Whisper doesn't provide fine-grain progress, so we mock it up to 78%
      final progressTimer = Timer.periodic(const Duration(milliseconds: 500), (
        timer,
      ) {
        if (_progress < 0.78 && currentState == ProcessingState.transcribing) {
          final newProgress = _progress + 0.02;
          _updateState(
            ProcessingState.transcribing,
            newProgress,
            'Transcribing speech with Whisper AI...',
          );
        }
      });

      final result = await _transcriptionRepo.transcribe(
        _audioPath!,
        language: language,
        style: style,
      );

      progressTimer.cancel(); // Cancel timer when done

      _rawWords = result.rawWords;
      _updateState(
        ProcessingState.transcribing,
        0.8,
        'Transcription complete ✓',
      );

      // Step 3: Generate captions
      if (_isCancelled) return;
      _updateState(
        ProcessingState.groupingCaptions,
        0.85,
        'Generating captions...',
      );

      _captions = result.captions;
      _updateState(
        ProcessingState.groupingCaptions,
        0.95,
        'Captions generated ✓',
      );

      // Done
      if (_isCancelled) return;
      _updateState(ProcessingState.done, 1.0, 'Processing complete!');

      _log.i(
        'Processing complete: ${_captions.length} captions from '
        '${_rawWords.length} words',
      );
    } on AppException catch (e) {
      _log.e('Processing failed: ${e.message}');
      _errorMessage = e.userFriendlyMessage;
      _updateState(ProcessingState.error, _progress, e.userFriendlyMessage);
    } catch (e) {
      _log.e('Processing failed unexpectedly', error: e);
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _updateState(ProcessingState.error, _progress, _errorMessage!);
    }
  }

  /// Cancels the current processing pipeline.
  void cancel() {
    _isCancelled = true;
    FFmpegUtils.cancelAll();
    _updateState(ProcessingState.idle, 0.0, 'Cancelled');
    _log.i('Processing cancelled');
  }

  /// Resets all state to initial values.
  void reset() {
    _currentState = ProcessingState.idle;
    _progress = 0.0;
    _statusMessage = '';
    _errorMessage = null;
    _captions = [];
    _rawWords = [];
    _audioPath = null;
    _isCancelled = false;
    notifyListeners();
  }

  void _updateState(ProcessingState state, double progress, String message) {
    _currentState = state;
    _progress = progress;
    _statusMessage = message;
    notifyListeners();
  }
}
