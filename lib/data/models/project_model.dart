import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import 'caption_model.dart';
import 'caption_style_model.dart';

/// Model representing a captioning project.
///
/// A project stores the video, all generated captions, style settings,
/// and export status.
class ProjectModel extends Equatable {
  final String id;
  final String name;
  final String videoPath;
  final String thumbnailPath;
  final List<CaptionModel> captions;
  final Duration videoDuration;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CaptionStyleModel style;
  final bool isExported;
  final String? exportPath;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.videoPath,
    this.thumbnailPath = '',
    this.captions = const [],
    this.videoDuration = Duration.zero,
    required this.createdAt,
    required this.updatedAt,
    this.style = const CaptionStyleModel(),
    this.isExported = false,
    this.exportPath,
  });

  /// Creates a new project with a unique ID and current timestamps.
  factory ProjectModel.create({
    required String name,
    required String videoPath,
    String thumbnailPath = '',
    Duration videoDuration = Duration.zero,
  }) {
    final now = DateTime.now();
    return ProjectModel(
      id: const Uuid().v4(),
      name: name,
      videoPath: videoPath,
      thumbnailPath: thumbnailPath,
      videoDuration: videoDuration,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates a [ProjectModel] from a database map.
  factory ProjectModel.fromDbMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Untitled',
      videoPath: map['videoPath'] as String? ?? '',
      thumbnailPath: map['thumbnailPath'] as String? ?? '',
      videoDuration: Duration(milliseconds: map['videoDuration'] as int? ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] as int? ?? 0,
      ),
      isExported: (map['isExported'] as int? ?? 0) == 1,
      exportPath: map['exportPath'] as String?,
      style:
          map['styleJson'] != null
              ? CaptionStyleModel.fromJsonString(map['styleJson'] as String)
              : const CaptionStyleModel(),
    );
  }

  /// Converts this model to a database-friendly map.
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'name': name,
      'videoPath': videoPath,
      'thumbnailPath': thumbnailPath,
      'videoDuration': videoDuration.inMilliseconds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isExported': isExported ? 1 : 0,
      'exportPath': exportPath,
      'styleJson': style.toJsonString(),
    };
  }

  /// Creates a [ProjectModel] from JSON.
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Untitled',
      videoPath: json['videoPath'] as String? ?? '',
      thumbnailPath: json['thumbnailPath'] as String? ?? '',
      captions:
          (json['captions'] as List<dynamic>?)
              ?.map((c) => CaptionModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      videoDuration: Duration(milliseconds: json['videoDuration'] as int? ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] as int? ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        json['updatedAt'] as int? ?? 0,
      ),
      style:
          json['style'] != null
              ? CaptionStyleModel.fromJson(
                json['style'] as Map<String, dynamic>,
              )
              : const CaptionStyleModel(),
      isExported: json['isExported'] as bool? ?? false,
      exportPath: json['exportPath'] as String?,
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'videoPath': videoPath,
      'thumbnailPath': thumbnailPath,
      'captions': captions.map((c) => c.toJson()).toList(),
      'videoDuration': videoDuration.inMilliseconds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'style': style.toJson(),
      'isExported': isExported,
      'exportPath': exportPath,
    };
  }

  /// Creates a copy with the given fields replaced.
  ProjectModel copyWith({
    String? id,
    String? name,
    String? videoPath,
    String? thumbnailPath,
    List<CaptionModel>? captions,
    Duration? videoDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
    CaptionStyleModel? style,
    bool? isExported,
    String? exportPath,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      videoPath: videoPath ?? this.videoPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      captions: captions ?? this.captions,
      videoDuration: videoDuration ?? this.videoDuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      style: style ?? this.style,
      isExported: isExported ?? this.isExported,
      exportPath: exportPath ?? this.exportPath,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    videoPath,
    thumbnailPath,
    captions,
    videoDuration,
    createdAt,
    updatedAt,
    style,
    isExported,
    exportPath,
  ];
}
