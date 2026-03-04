import 'package:logger/logger.dart';

import '../datasources/whisper_datasource.dart';
import '../models/caption_model.dart';
import '../models/caption_style_model.dart';
import '../models/word_timestamp_model.dart';

/// Repository for transcription operations.
///
/// Abstracts the speech-to-text datasource and provides methods
/// for transcribing audio and managing transcription results.
class TranscriptionRepository {
  final SpeechToTextDatasource _datasource;
  static final _log = Logger();

  TranscriptionRepository({SpeechToTextDatasource? datasource})
    : _datasource = datasource ?? WhisperDatasource();

  /// Transcribes an audio file and returns captions.
  Future<TranscriptionResult> transcribe(
    String audioPath, {
    String? language,
    CaptionStyleModel style = const CaptionStyleModel(),
  }) async {
    _log.i('Starting transcription for: $audioPath, language: $language');
    return _datasource.transcribeAudio(
      audioPath,
      language: language,
      style: style,
    );
  }

  /// Re-groups existing words into captions with a new style.
  List<CaptionModel> regroupCaptions(
    List<WordTimestampModel> words,
    CaptionStyleModel style,
  ) {
    return WhisperDatasource.groupWordsIntoCaptions(words, style);
  }
}
