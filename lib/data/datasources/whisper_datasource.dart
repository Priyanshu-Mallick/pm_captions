import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/caption_parser_utils.dart';
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
        final rawWords = CaptionParserUtils.parseWords(data);
        final captions = CaptionParserUtils.groupWordsIntoCaptions(
          rawWords,
          style,
        );
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
