import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import 'caption_style_model.dart';
import 'word_timestamp_model.dart';

/// Model representing a single caption with its text, timing, and style.
///
/// Each caption contains a list of words with their timestamps for
/// word-level highlighting (karaoke effect).
class CaptionModel extends Equatable {
  /// Unique identifier for this caption.
  final String id;

  /// The caption text.
  final String text;

  /// Individual words with their timing information.
  final List<WordTimestampModel> words;

  /// When this caption starts in the video.
  final Duration startTime;

  /// When this caption ends in the video.
  final Duration endTime;

  /// Visual style applied to this caption.
  final CaptionStyleModel style;

  /// Whether this caption has been manually edited by the user.
  final bool isEdited;

  const CaptionModel({
    required this.id,
    required this.text,
    required this.words,
    required this.startTime,
    required this.endTime,
    this.style = const CaptionStyleModel(),
    this.isEdited = false,
  });

  /// Creates a new [CaptionModel] with a generated UUID.
  factory CaptionModel.create({
    required String text,
    required List<WordTimestampModel> words,
    required Duration startTime,
    required Duration endTime,
    CaptionStyleModel style = const CaptionStyleModel(),
  }) {
    return CaptionModel(
      id: const Uuid().v4(),
      text: text,
      words: words,
      startTime: startTime,
      endTime: endTime,
      style: style,
    );
  }

  /// The duration this caption is visible.
  Duration get duration => endTime - startTime;

  /// Creates a [CaptionModel] from a JSON map.
  factory CaptionModel.fromJson(Map<String, dynamic> json) {
    final wordsJson = json['words'];
    List<WordTimestampModel> words;

    if (wordsJson is String) {
      final decoded = jsonDecode(wordsJson) as List;
      words =
          decoded
              .map(
                (w) => WordTimestampModel.fromJson(w as Map<String, dynamic>),
              )
              .toList();
    } else if (wordsJson is List) {
      words =
          wordsJson
              .map(
                (w) => WordTimestampModel.fromJson(w as Map<String, dynamic>),
              )
              .toList();
    } else {
      words = [];
    }

    return CaptionModel(
      id: json['id'] as String? ?? const Uuid().v4(),
      text: json['text'] as String? ?? '',
      words: words,
      startTime: Duration(milliseconds: json['startMs'] as int? ?? 0),
      endTime: Duration(milliseconds: json['endMs'] as int? ?? 0),
      style:
          json['style'] != null
              ? (json['style'] is String
                  ? CaptionStyleModel.fromJsonString(json['style'] as String)
                  : CaptionStyleModel.fromJson(
                    json['style'] as Map<String, dynamic>,
                  ))
              : const CaptionStyleModel(),
      isEdited: json['isEdited'] as bool? ?? false,
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'words': words.map((w) => w.toJson()).toList(),
      'startMs': startTime.inMilliseconds,
      'endMs': endTime.inMilliseconds,
      'style': style.toJson(),
      'isEdited': isEdited,
    };
  }

  /// Converts this model to a database-friendly map (words as JSON string).
  Map<String, dynamic> toDbMap(String projectId, int displayOrder) {
    return {
      'id': id,
      'projectId': projectId,
      'text': text,
      'startMs': startTime.inMilliseconds,
      'endMs': endTime.inMilliseconds,
      'wordsJson': jsonEncode(words.map((w) => w.toJson()).toList()),
      'isEdited': isEdited ? 1 : 0,
      'displayOrder': displayOrder,
    };
  }

  /// Creates a copy with the given fields replaced.
  CaptionModel copyWith({
    String? id,
    String? text,
    List<WordTimestampModel>? words,
    Duration? startTime,
    Duration? endTime,
    CaptionStyleModel? style,
    bool? isEdited,
  }) {
    return CaptionModel(
      id: id ?? this.id,
      text: text ?? this.text,
      words: words ?? this.words,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      style: style ?? this.style,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  @override
  List<Object?> get props => [
    id,
    text,
    words,
    startTime,
    endTime,
    style,
    isEdited,
  ];
}
