import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pm_captions/core/errors/exceptions.dart';
import 'package:pm_captions/data/datasources/hinglish_transliteration_service.dart';
import 'package:pm_captions/data/models/word_timestamp_model.dart';

void main() {
  const parser = HinglishTransliterationResponseParser();
  const source = [
    WordTimestampModel(word: 'आज', start: 0.1, end: 0.4, confidence: 0.91),
    WordTimestampModel(word: 'meeting', start: 0.5, end: 0.9, confidence: 0.87),
    WordTimestampModel(word: 'है?', start: 1.0, end: 1.2, confidence: 0.8),
  ];

  dynamic response(List<Map<String, dynamic>> words) => {
    'choices': [
      {
        'message': {
          'content': jsonEncode({'words': words}),
        },
      },
    ],
  };

  test('applies Roman words without changing timing or confidence', () {
    final result = parser.parse(
      response([
        {'id': 0, 'text': 'aaj'},
        {'id': 1, 'text': 'meeting'},
        {'id': 2, 'text': 'hai?'},
      ]),
      source,
    );

    expect(result.map((word) => word.word), ['aaj', 'meeting', 'hai?']);
    for (var index = 0; index < source.length; index++) {
      expect(result[index].start, source[index].start);
      expect(result[index].end, source[index].end);
      expect(result[index].confidence, source[index].confidence);
    }
  });

  test('rejects changes to words already written in Latin script', () {
    expect(
      () => parser.parse(
        response([
          {'id': 0, 'text': 'aaj'},
          {'id': 1, 'text': 'baithak'},
          {'id': 2, 'text': 'hai?'},
        ]),
        source,
      ),
      throwsA(isA<HinglishConversionException>()),
    );
  });

  test('rejects missing, duplicate, multi-word, and native-script output', () {
    final invalidOutputs = [
      [
        {'id': 0, 'text': 'aaj'},
        {'id': 1, 'text': 'meeting'},
      ],
      [
        {'id': 0, 'text': 'aaj'},
        {'id': 0, 'text': 'meeting'},
        {'id': 2, 'text': 'hai?'},
      ],
      [
        {'id': 0, 'text': 'aaj kal'},
        {'id': 1, 'text': 'meeting'},
        {'id': 2, 'text': 'hai?'},
      ],
      [
        {'id': 0, 'text': 'आज'},
        {'id': 1, 'text': 'meeting'},
        {'id': 2, 'text': 'hai?'},
      ],
      [
        {'id': 0, 'text': ''},
        {'id': 1, 'text': 'meeting'},
        {'id': 2, 'text': 'hai?'},
      ],
      [
        {'id': 0, 'text': 'aaj'},
        {'id': 1, 'text': 'meeting'},
        {'id': 2, 'text': 'hai'},
      ],
    ];

    for (final output in invalidOutputs) {
      expect(
        () => parser.parse(response(output), source),
        throwsA(isA<HinglishConversionException>()),
      );
    }
  });
}
