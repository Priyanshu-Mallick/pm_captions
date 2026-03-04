import 'word_entity.dart';

/// Domain entity representing a caption.
class CaptionEntity {
  final String id;
  final String text;
  final Duration startTime;
  final Duration endTime;
  final List<WordEntity> words;

  const CaptionEntity({
    required this.id,
    required this.text,
    required this.startTime,
    required this.endTime,
    this.words = const [],
  });
}
