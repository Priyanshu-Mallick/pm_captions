import 'package:equatable/equatable.dart';

/// Represents a single word with its timing information from Whisper API.
///
/// Each word has a start and end timestamp (in seconds) along with
/// a confidence score from the speech-to-text engine.
class WordTimestampModel extends Equatable {
  /// The spoken word text.
  final String word;

  /// Start time in seconds when the word begins.
  final double start;

  /// End time in seconds when the word ends.
  final double end;

  /// Confidence score from the STT engine (0.0 - 1.0).
  final double confidence;

  const WordTimestampModel({
    required this.word,
    required this.start,
    required this.end,
    this.confidence = 1.0,
  });

  /// Creates a [WordTimestampModel] from a JSON map.
  factory WordTimestampModel.fromJson(Map<String, dynamic> json) {
    return WordTimestampModel(
      word: (json['word'] as String? ?? '').trim(),
      start: (json['start'] as num?)?.toDouble() ?? 0.0,
      end: (json['end'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {'word': word, 'start': start, 'end': end, 'confidence': confidence};
  }

  /// Duration of this word in the audio.
  Duration get wordDuration =>
      Duration(milliseconds: ((end - start) * 1000).round());

  /// Start time as a [Duration].
  Duration get startDuration => Duration(milliseconds: (start * 1000).round());

  /// End time as a [Duration].
  Duration get endDuration => Duration(milliseconds: (end * 1000).round());

  /// Creates a copy with the given fields replaced.
  WordTimestampModel copyWith({
    String? word,
    double? start,
    double? end,
    double? confidence,
  }) {
    return WordTimestampModel(
      word: word ?? this.word,
      start: start ?? this.start,
      end: end ?? this.end,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  List<Object?> get props => [word, start, end, confidence];
}
