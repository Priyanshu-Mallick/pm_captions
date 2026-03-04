/// Domain entity representing a single word with timing.
class WordEntity {
  final String word;
  final double start;
  final double end;

  const WordEntity({
    required this.word,
    required this.start,
    required this.end,
  });
}
