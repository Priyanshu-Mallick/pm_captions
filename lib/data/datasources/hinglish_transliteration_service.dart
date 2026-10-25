import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/word_timestamp_model.dart';
import 'whisper_datasource.dart';

/// Converts native-script Hindi words to Roman Hinglish while retaining timing.
abstract class HinglishTransliterationService {
  Future<List<WordTimestampModel>> transliterate(
    List<WordTimestampModel> words,
  );
}

/// Groq chat-completions implementation of Hinglish transliteration.
class GroqHinglishTransliterationService
    implements HinglishTransliterationService {
  static const modelId = 'openai/gpt-oss-20b';

  final Dio? _dio;
  final Future<String?> Function() _apiKeyProvider;
  final HinglishTransliterationResponseParser _responseParser;

  GroqHinglishTransliterationService({
    Dio? dio,
    Future<String?> Function()? apiKeyProvider,
    HinglishTransliterationResponseParser? responseParser,
  }) : _dio = dio,
       _apiKeyProvider = apiKeyProvider ?? WhisperDatasource.getApiKey,
       _responseParser =
           responseParser ?? const HinglishTransliterationResponseParser();

  @override
  Future<List<WordTimestampModel>> transliterate(
    List<WordTimestampModel> words,
  ) async {
    if (words.isEmpty) return const [];

    final Dio dio;
    if (_dio case final injectedDio?) {
      dio = injectedDio;
    } else {
      final apiKey = await _apiKeyProvider();
      if (apiKey == null || apiKey.isEmpty) {
        throw NoApiKeyException();
      }
      dio = ApiClient.create(apiKey: apiKey);
    }
    final indexedWords = [
      for (var index = 0; index < words.length; index++)
        {'id': index, 'text': words[index].word},
    ];

    try {
      final response = await dio.post<dynamic>(
        'chat/completions',
        data: {
          'model': modelId,
          'temperature': 0,
          'reasoning_effort': 'low',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You transliterate caption tokens into natural Roman-script '
                  'Hinglish. Transliterate Hindi written in Devanagari into '
                  'Latin letters. Do not translate meaning. Keep words already '
                  'written in Latin script unchanged. Preserve punctuation and '
                  'letter casing where possible. Return exactly one non-empty '
                  'token for every input id, in the same order. Never join or '
                  'split tokens and never add commentary.',
            },
            {
              'role': 'user',
              'content': jsonEncode({'words': indexedWords}),
            },
          ],
          'response_format': {
            'type': 'json_schema',
            'json_schema': {
              'name': 'hinglish_words',
              'strict': true,
              'schema': {
                'type': 'object',
                'properties': {
                  'words': {
                    'type': 'array',
                    'items': {
                      'type': 'object',
                      'properties': {
                        'id': {'type': 'integer'},
                        'text': {'type': 'string'},
                      },
                      'required': ['id', 'text'],
                      'additionalProperties': false,
                    },
                  },
                },
                'required': ['words'],
                'additionalProperties': false,
              },
            },
          },
        },
        options: Options(receiveTimeout: const Duration(minutes: 2)),
      );

      return _responseParser.parse(response.data, words);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        throw InvalidApiKeyException(statusCode: statusCode!);
      }
      throw HinglishConversionException(
        details: 'Groq request failed with HTTP ${statusCode ?? "unknown"}',
      );
    } on AppException {
      rethrow;
    } catch (error) {
      throw HinglishConversionException(details: error.toString());
    }
  }
}

/// Validates Groq's structured response and reapplies the original word timing.
class HinglishTransliterationResponseParser {
  const HinglishTransliterationResponseParser();

  List<WordTimestampModel> parse(
    dynamic responseData,
    List<WordTimestampModel> sourceWords,
  ) {
    try {
      final response = _asMap(responseData, 'response');
      final choices = response['choices'];
      if (choices is! List || choices.isEmpty) {
        throw const FormatException('Response has no choices');
      }

      final choice = _asMap(choices.first, 'choice');
      final message = _asMap(choice['message'], 'message');
      final content = message['content'];
      if (content is! String || content.trim().isEmpty) {
        throw const FormatException('Response content is empty');
      }

      final payload = _asMap(jsonDecode(content), 'content');
      final outputWords = payload['words'];
      if (outputWords is! List || outputWords.length != sourceWords.length) {
        throw const FormatException('Output word count does not match input');
      }

      final replacements = <int, String>{};
      for (final item in outputWords) {
        final word = _asMap(item, 'word');
        final id = word['id'];
        final text = word['text'];
        if (id is! int || id < 0 || id >= sourceWords.length) {
          throw const FormatException('Output contains an invalid word id');
        }
        if (replacements.containsKey(id)) {
          throw const FormatException('Output contains a duplicate word id');
        }
        if (text is! String || text.trim().isEmpty) {
          throw const FormatException('Output contains an empty word');
        }

        final normalized = text.trim();
        if (RegExp(r'\s').hasMatch(normalized)) {
          throw const FormatException('Output split or joined a word');
        }
        final sourceText = sourceWords[id].word.trim();
        final devanagari = RegExp(r'[\u0900-\u097F]');
        if (!devanagari.hasMatch(sourceText) && normalized != sourceText) {
          throw const FormatException('Output changed a non-Hindi word');
        }
        if (devanagari.hasMatch(normalized)) {
          throw const FormatException('Output still contains Devanagari text');
        }
        final sourcePunctuation = RegExp(
          r'[.,!?;:]+$',
        ).firstMatch(sourceText)?.group(0);
        if (sourcePunctuation != null &&
            !normalized.endsWith(sourcePunctuation)) {
          throw const FormatException('Output changed trailing punctuation');
        }
        replacements[id] = normalized;
      }

      if (replacements.length != sourceWords.length) {
        throw const FormatException('Output word ids do not match input');
      }

      return [
        for (var index = 0; index < sourceWords.length; index++)
          sourceWords[index].copyWith(word: replacements[index]),
      ];
    } on HinglishConversionException {
      rethrow;
    } catch (error) {
      throw HinglishConversionException(details: error.toString());
    }
  }

  Map<String, dynamic> _asMap(dynamic value, String name) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw FormatException('$name is not a JSON object');
  }
}
