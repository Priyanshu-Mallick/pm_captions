import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/caption_model.dart';
import '../models/caption_style_model.dart';
import '../models/word_timestamp_model.dart';

/// Result of a transcription operation.
class TranscriptionResult {
  final List<CaptionModel> captions;
  final List<WordTimestampModel> rawWords;
  final String? detectedLanguage;

  const TranscriptionResult({
    required this.captions,
    required this.rawWords,
    this.detectedLanguage,
  });
}

/// Abstract interface for speech-to-text datasources.
abstract class SpeechToTextDatasource {
  /// Transcribes an audio file and returns structured caption data.
  Future<TranscriptionResult> transcribeAudio(
    String audioPath, {
    String? language,
    CaptionStyleModel style,
  });
}

/// Groq Whisper API implementation of [SpeechToTextDatasource].
///
/// Uses the free Groq API (https://console.groq.com) with the
/// whisper-large-v3 model, which is compatible with the OpenAI
/// Whisper API format.
class WhisperDatasource implements SpeechToTextDatasource {
  static final _log = Logger();
  static const _apiKeyPref = 'groq_api_key';
  static const _maxRetries = 3;

  /// Retrieves the stored API key from SharedPreferences.
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref);
  }

  /// Saves the API key to SharedPreferences.
  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key);
  }

  /// Checks if an API key is stored.
  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Validates Groq API key format (starts with 'gsk_').
  static bool isValidKeyFormat(String key) {
    return key.startsWith('gsk_') && key.length >= 40;
  }

  /// Tests the API connection with the given key.
  static Future<bool> testConnection(String apiKey) async {
    try {
      final dio = ApiClient.create(apiKey: apiKey);
      final response = await dio.get('models');
      return response.statusCode == 200;
    } catch (e) {
      _log.w('API test connection failed', error: e);
      return false;
    }
  }

  @override
  Future<TranscriptionResult> transcribeAudio(
    String audioPath, {
    String? language,
    CaptionStyleModel style = const CaptionStyleModel(),
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw NoApiKeyException();
    }

    final dio = ApiClient.create(apiKey: apiKey);
    final file = File(audioPath);

    if (!await file.exists()) {
      throw AudioExtractionException(
        details: 'Audio file not found: $audioPath',
      );
    }

    // Retry logic with exponential backoff
    Exception? lastException;
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          final delay = Duration(seconds: (1 << attempt)); // 2, 4 seconds
          _log.i('Retry attempt ${attempt + 1} after ${delay.inSeconds}s');
          await Future.delayed(delay);
        }

        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            audioPath,
            filename: 'audio.wav',
          ),
          'model': 'whisper-large-v3',
          'response_format': 'verbose_json',
          'timestamp_granularities[]': ['word', 'segment'],
          if (language != null) 'language': language,
        });

        _log.i('Sending transcription request (attempt ${attempt + 1})');

        final response = await dio.post(
          'audio/transcriptions',
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
            receiveTimeout: const Duration(minutes: 5),
          ),
        );

        if (response.statusCode != 200) {
          throw ApiException(
            statusCode: response.statusCode,
            responseBody: response.data.toString(),
          );
        }

        final data = response.data as Map<String, dynamic>;
        final rawWords = _parseWords(data);
        final captions = groupWordsIntoCaptions(rawWords, style);
        final detectedLang = data['language'] as String?;

        _log.i(
          'Transcription complete: ${rawWords.length} words, '
          '${captions.length} captions, language=$detectedLang',
        );

        return TranscriptionResult(
          captions: captions,
          rawWords: rawWords,
          detectedLanguage: detectedLang,
        );
      } on DioException catch (e) {
        lastException = ApiException(
          statusCode: e.response?.statusCode,
          responseBody: e.response?.data?.toString(),
        );
        _log.w('Transcription attempt ${attempt + 1} failed', error: e);
      } catch (e) {
        if (e is AppException) rethrow;
        lastException = GenericException(details: e.toString());
        _log.w('Transcription attempt ${attempt + 1} failed', error: e);
      }
    }

    throw lastException ?? GenericException(details: 'Transcription failed');
  }

  /// Parses word-level timestamps from the Whisper API response.
  List<WordTimestampModel> _parseWords(Map<String, dynamic> data) {
    final wordsData = data['words'] as List<dynamic>?;
    if (wordsData == null || wordsData.isEmpty) {
      // Fall back to segment-level data
      return _parseSegmentsAsWords(data);
    }

    return wordsData
        .map((w) => WordTimestampModel.fromJson(w as Map<String, dynamic>))
        .toList();
  }

  /// Falls back to parsing segments when word-level data is unavailable.
  List<WordTimestampModel> _parseSegmentsAsWords(Map<String, dynamic> data) {
    final segments = data['segments'] as List<dynamic>?;
    if (segments == null) return [];

    final words = <WordTimestampModel>[];
    for (final segment in segments) {
      final segMap = segment as Map<String, dynamic>;
      final text = segMap['text'] as String? ?? '';
      final start = (segMap['start'] as num?)?.toDouble() ?? 0.0;
      final end = (segMap['end'] as num?)?.toDouble() ?? 0.0;

      final segWords = text.trim().split(RegExp(r'\s+'));
      if (segWords.isEmpty) continue;

      final wordDuration = (end - start) / segWords.length;
      for (var i = 0; i < segWords.length; i++) {
        words.add(
          WordTimestampModel(
            word: segWords[i],
            start: start + (i * wordDuration),
            end: start + ((i + 1) * wordDuration),
            confidence: 0.8,
          ),
        );
      }
    }

    return words;
  }

  /// Groups individual words into caption segments.
  ///
  /// Splits captions based on:
  /// - [style.maxWordsPerLine] words per caption
  /// - Natural pauses > 0.5 seconds between words
  /// - Punctuation (period, question mark, exclamation mark)
  static List<CaptionModel> groupWordsIntoCaptions(
    List<WordTimestampModel> words,
    CaptionStyleModel style,
  ) {
    if (words.isEmpty) return [];

    final captions = <CaptionModel>[];
    var currentWords = <WordTimestampModel>[];
    final maxWords = style.maxWordsPerLine;

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      currentWords.add(word);

      final isLastWord = i == words.length - 1;
      final reachedMaxWords = currentWords.length >= maxWords;

      // Check for natural pause (> 0.5s gap to next word)
      final hasNaturalPause =
          !isLastWord && (words[i + 1].start - word.end) > 0.5;

      // Check for sentence-ending punctuation
      final endsWithPunctuation =
          word.word.endsWith('.') ||
          word.word.endsWith('?') ||
          word.word.endsWith('!');

      if (isLastWord ||
          reachedMaxWords ||
          hasNaturalPause ||
          endsWithPunctuation) {
        final text = currentWords.map((w) => w.word).join(' ');
        final startTime = Duration(
          milliseconds: (currentWords.first.start * 1000).round(),
        );
        final endTime = Duration(
          milliseconds: (currentWords.last.end * 1000).round(),
        );

        captions.add(
          CaptionModel(
            id: const Uuid().v4(),
            text: text,
            words: List.from(currentWords),
            startTime: startTime,
            endTime: endTime,
            style: style,
          ),
        );

        currentWords = [];
      }
    }

    return captions;
  }
}

/// Stub implementation for AssemblyAI speech-to-text.
class AssemblyAIDatasource implements SpeechToTextDatasource {
  @override
  Future<TranscriptionResult> transcribeAudio(
    String audioPath, {
    String? language,
    CaptionStyleModel style = const CaptionStyleModel(),
  }) async {
    throw UnimplementedError('AssemblyAI integration not yet implemented');
  }
}

/// Stub implementation for Google Cloud speech-to-text.
class GoogleCloudSTTDatasource implements SpeechToTextDatasource {
  @override
  Future<TranscriptionResult> transcribeAudio(
    String audioPath, {
    String? language,
    CaptionStyleModel style = const CaptionStyleModel(),
  }) async {
    throw UnimplementedError(
      'Google Cloud STT integration not yet implemented',
    );
  }
}
