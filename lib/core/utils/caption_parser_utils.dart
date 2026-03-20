import 'package:uuid/uuid.dart';

import '../../data/models/caption_model.dart';
import '../../data/models/caption_style_model.dart';
import '../../data/models/word_timestamp_model.dart';

class CaptionParserUtils {
  /// Parses word-level timestamps from the Whisper API response.
  static List<WordTimestampModel> parseWords(Map<String, dynamic> data) {
    final wordsData = data['words'] as List<dynamic>?;
    if (wordsData == null || wordsData.isEmpty) {
      // Fall back to segment-level data
      return parseSegmentsAsWords(data);
    }

    return wordsData
        .map((w) => WordTimestampModel.fromJson(w as Map<String, dynamic>))
        .toList();
  }

  /// Falls back to parsing segments when word-level data is unavailable.
  static List<WordTimestampModel> parseSegmentsAsWords(
    Map<String, dynamic> data,
  ) {
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
