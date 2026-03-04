import 'package:equatable/equatable.dart';

/// Video export resolution options.
enum ExportResolution {
  /// 1280 × 720
  p720,

  /// 1920 × 1080
  p1080,

  /// Keep original video resolution
  original,
}

/// Model representing export configuration.
///
/// Controls the output quality, format, and what files to generate.
class ExportSettingsModel extends Equatable {
  /// Output video resolution.
  final ExportResolution resolution;

  /// Frames per second.
  final int fps;

  /// Video bitrate as FFmpeg string (e.g. "5M").
  final String videoBitrate;

  /// Whether to burn subtitles into the video (hard subs).
  final bool includeHardSubtitles;

  /// Whether to also export an SRT file.
  final bool exportSRT;

  /// Whether to also export a VTT file.
  final bool exportVTT;

  /// Output container format.
  final String outputFormat;

  const ExportSettingsModel({
    this.resolution = ExportResolution.original,
    this.fps = 30,
    this.videoBitrate = '5M',
    this.includeHardSubtitles = true,
    this.exportSRT = false,
    this.exportVTT = false,
    this.outputFormat = 'mp4',
  });

  /// Returns the FFmpeg scale filter string for the selected resolution.
  /// Returns `null` if resolution is original (no scaling needed).
  String? get scaleFilter {
    switch (resolution) {
      case ExportResolution.p720:
        return 'scale=-2:720';
      case ExportResolution.p1080:
        return 'scale=-2:1080';
      case ExportResolution.original:
        return null;
    }
  }

  /// The human-readable label for the resolution.
  String get resolutionLabel {
    switch (resolution) {
      case ExportResolution.p720:
        return '720p';
      case ExportResolution.p1080:
        return '1080p';
      case ExportResolution.original:
        return 'Original';
    }
  }

  /// Creates a copy with the given fields replaced.
  ExportSettingsModel copyWith({
    ExportResolution? resolution,
    int? fps,
    String? videoBitrate,
    bool? includeHardSubtitles,
    bool? exportSRT,
    bool? exportVTT,
    String? outputFormat,
  }) {
    return ExportSettingsModel(
      resolution: resolution ?? this.resolution,
      fps: fps ?? this.fps,
      videoBitrate: videoBitrate ?? this.videoBitrate,
      includeHardSubtitles: includeHardSubtitles ?? this.includeHardSubtitles,
      exportSRT: exportSRT ?? this.exportSRT,
      exportVTT: exportVTT ?? this.exportVTT,
      outputFormat: outputFormat ?? this.outputFormat,
    );
  }

  /// Creates an [ExportSettingsModel] from JSON.
  factory ExportSettingsModel.fromJson(Map<String, dynamic> json) {
    return ExportSettingsModel(
      resolution: ExportResolution.values[json['resolution'] as int? ?? 2],
      fps: json['fps'] as int? ?? 30,
      videoBitrate: json['videoBitrate'] as String? ?? '5M',
      includeHardSubtitles: json['includeHardSubtitles'] as bool? ?? true,
      exportSRT: json['exportSRT'] as bool? ?? false,
      exportVTT: json['exportVTT'] as bool? ?? false,
      outputFormat: json['outputFormat'] as String? ?? 'mp4',
    );
  }

  /// Converts this model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'resolution': resolution.index,
      'fps': fps,
      'videoBitrate': videoBitrate,
      'includeHardSubtitles': includeHardSubtitles,
      'exportSRT': exportSRT,
      'exportVTT': exportVTT,
      'outputFormat': outputFormat,
    };
  }

  @override
  List<Object?> get props => [
    resolution,
    fps,
    videoBitrate,
    includeHardSubtitles,
    exportSRT,
    exportVTT,
    outputFormat,
  ];
}
