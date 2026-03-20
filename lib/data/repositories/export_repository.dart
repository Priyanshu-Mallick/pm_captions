import 'package:logger/logger.dart';

import '../../core/utils/ffmpeg_utils.dart';
import '../../core/utils/srt_generator.dart';
import '../../core/utils/file_utils.dart';
import '../models/caption_model.dart';
import '../models/caption_style_model.dart';
import '../models/export_settings_model.dart';

/// Repository for video export operations.
class ExportRepository {
  static final _log = Logger();

  /// Exports a video with burned-in subtitles.
  ///
  /// Returns the path to the exported video file.
  Future<String> exportVideoWithSubtitles({
    required String videoPath,
    required List<CaptionModel> captions,
    required CaptionStyleModel style,
    required ExportSettingsModel settings,
    void Function(double progress)? onProgress,
  }) async {
    _log.i('Starting video export with subtitles');

    // Create output path
    final outputPath = await FileUtils.createOutputFilePath(
      settings.outputFormat,
    );

    // Determine if we need to compress
    final needsCompression = settings.resolution != ExportResolution.original;

    // Burn subtitles using drawtext filter
    await FFmpegUtils.burnSubtitles(
      videoPath: videoPath,
      captions: captions,
      style: style,
      outputPath: outputPath,
      onProgress: (p) {
        if (onProgress != null) {
          // If we compress later, burning is the first 50%. Else, it's 100%.
          final scaledProgress = needsCompression ? p * 0.5 : p;
          onProgress(scaledProgress);
        }
      },
    );

    // Compress if resolution is not original
    if (needsCompression) {
      final compressedPath = await FileUtils.createOutputFilePath(
        settings.outputFormat,
      );
      await FFmpegUtils.compressVideo(
        videoPath: outputPath,
        settings: settings,
        outputPath: compressedPath,
        onProgress: (p) {
          if (onProgress != null) {
            // Compressing is the second 50%
            onProgress(0.5 + (p * 0.5));
          }
        },
      );
      await FileUtils.deleteFile(outputPath);
      return compressedPath;
    }

    _log.i('Export complete: $outputPath');
    return outputPath;
  }

  /// Exports captions as an SRT file.
  Future<String> exportSrt(List<CaptionModel> captions) async {
    return SrtGenerator.generateSrt(captions);
  }

  /// Exports captions as a VTT file.
  Future<String> exportVtt(List<CaptionModel> captions) async {
    return SrtGenerator.generateVtt(captions);
  }
}
