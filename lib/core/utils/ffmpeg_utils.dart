import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:logger/logger.dart';

import '../../data/models/caption_style_model.dart';
import '../../data/models/export_settings_model.dart';
import '../errors/exceptions.dart';
import 'file_utils.dart';

/// Utility class for FFmpeg operations.
///
/// Provides methods for audio extraction, subtitle burning, video
/// duration retrieval, thumbnail generation, and video compression.
class FFmpegUtils {
  FFmpegUtils._();

  static final _log = Logger();

  /// Extracts audio from a video as 16kHz mono WAV for Whisper.
  ///
  /// Saves to the temp directory and returns the output file path.
  static Future<String> extractAudio(String videoPath) async {
    final outputPath = await FileUtils.createTempFilePath('wav');

    final command =
        '-y -i "$videoPath" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$outputPath"';

    _log.i('Extracting audio: $command');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      _log.e('Audio extraction failed: $logs');
      throw AudioExtractionException(
        details: 'FFmpeg return code: ${returnCode?.getValue()}',
      );
    }

    final outputFile = File(outputPath);
    if (!await outputFile.exists() || await outputFile.length() == 0) {
      throw AudioExtractionException(
        details: 'Output file is empty or missing',
      );
    }

    _log.i('Audio extracted to: $outputPath');
    return outputPath;
  }

  /// Burns subtitles into a video using an SRT file and caption style.
  ///
  /// Generates an ASS-style `force_style` filter from the [style] parameter.
  static Future<void> burnSubtitles({
    required String videoPath,
    required String srtPath,
    required CaptionStyleModel style,
    required String outputPath,
    void Function(double)? onProgress,
  }) async {
    await FileUtils.ensureDirectoryExists(outputPath);

    final forceStyle = style.toFFmpegStyle();
    // Escape special characters in paths for the subtitles filter
    final escapedSrtPath = srtPath
        .replaceAll("'", "\\'")
        .replaceAll(':', '\\:');

    final command =
        '-y -i "$videoPath" '
        '-vf "subtitles=\'$escapedSrtPath\':force_style=\'$forceStyle\'" '
        '-c:a copy "$outputPath"';

    _log.i('Burning subtitles: $command');

    if (onProgress != null) {
      final duration = await getVideoDuration(videoPath);
      final totalMs = duration.inMilliseconds.toDouble();

      FFmpegKitConfig.enableStatisticsCallback((stats) {
        if (totalMs > 0) {
          final time = stats.getTime().toDouble();
          final progress = (time / totalMs).clamp(0.0, 1.0);
          onProgress(progress);
        }
      });
    }

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      _log.e('Subtitle burning failed: $logs');
      throw FFmpegException(
        command: 'burnSubtitles',
        returnCode: returnCode?.getValue(),
      );
    }

    _log.i('Subtitles burned to: $outputPath');
  }

  /// Returns the duration of a video file.
  static Future<Duration> getVideoDuration(String videoPath) async {
    final session = await FFprobeKit.getMediaInformation(videoPath);
    final info = session.getMediaInformation();

    if (info == null) {
      _log.w('Could not get media info for: $videoPath');
      return Duration.zero;
    }

    final durationStr = info.getDuration();
    if (durationStr == null) {
      return Duration.zero;
    }

    final seconds = double.tryParse(durationStr) ?? 0.0;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  /// Generates a thumbnail from the video at 0.1 seconds.
  ///
  /// Returns the path to the generated JPEG file.
  static Future<String> generateThumbnail(String videoPath) async {
    final outputPath = await FileUtils.createTempFilePath('jpg');

    final command =
        '-y -i "$videoPath" -ss 0.1 -vframes 1 -q:v 2 "$outputPath"';

    _log.i('Generating thumbnail: $command');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      _log.w('Thumbnail generation failed, using empty path');
      return '';
    }

    return outputPath;
  }

  /// Compresses or re-encodes a video with the specified export settings.
  ///
  /// Optionally scales resolution and applies bitrate settings.
  static Future<void> compressVideo({
    required String videoPath,
    required ExportSettingsModel settings,
    required String outputPath,
    void Function(double progress)? onProgress,
  }) async {
    await FileUtils.ensureDirectoryExists(outputPath);

    // Build filter chain
    final filters = <String>[];
    final scaleFilter = settings.scaleFilter;
    if (scaleFilter != null) {
      filters.add(scaleFilter);
    }

    final filterStr = filters.isNotEmpty ? '-vf "${filters.join(',')}"' : '';

    final command =
        '-y -i "$videoPath" '
        '$filterStr '
        '-b:v ${settings.videoBitrate} '
        '-r ${settings.fps} '
        '-c:a copy "$outputPath"';

    _log.i('Compressing video: $command');

    // Set up progress callback if provided
    if (onProgress != null) {
      final duration = await getVideoDuration(videoPath);
      final totalMs = duration.inMilliseconds.toDouble();

      FFmpegKitConfig.enableStatisticsCallback((stats) {
        if (totalMs > 0) {
          final time = stats.getTime().toDouble();
          final progress = (time / totalMs).clamp(0.0, 1.0);
          onProgress(progress);
        }
      });
    }

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      _log.e('Video compression failed: $logs');
      throw FFmpegException(
        command: 'compressVideo',
        returnCode: returnCode?.getValue(),
      );
    }

    _log.i('Video compressed to: $outputPath');
  }

  /// Cancels all running FFmpeg sessions.
  static Future<void> cancelAll() async {
    await FFmpegKit.cancel();
  }
}
