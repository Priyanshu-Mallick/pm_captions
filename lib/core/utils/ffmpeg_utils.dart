import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:logger/logger.dart';

import '../../data/models/caption_model.dart';
import '../../data/models/caption_style_model.dart';
import '../../data/models/export_settings_model.dart';
import '../errors/exceptions.dart';
import 'caption_image_renderer.dart';
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

  /// Returns the video bitrate in bits/s, or null if unavailable.
  static Future<String?> _getVideoBitrate(String videoPath) async {
    final session = await FFprobeKit.getMediaInformation(videoPath);
    final info = session.getMediaInformation();
    if (info == null) return null;

    final streams = info.getStreams();
    for (final stream in streams) {
      final type = stream.getType();
      if (type == 'video') {
        final bitrate = stream.getBitrate();
        if (bitrate != null) return bitrate;
      }
    }

    return info.getBitrate();
  }

  /// Returns the video resolution as (width, height).
  static Future<(int, int)> _getVideoResolution(String videoPath) async {
    final session = await FFprobeKit.getMediaInformation(videoPath);
    final info = session.getMediaInformation();
    if (info == null) return (1920, 1080);

    final streams = info.getStreams();
    for (final stream in streams) {
      if (stream.getType() == 'video') {
        final width = stream.getWidth();
        final height = stream.getHeight();
        if (width != null && height != null) {
          return (width, height);
        }
      }
    }
    return (1920, 1080);
  }

  /// Burns captions into a video using Flutter-rendered overlay images.
  ///
  /// Each caption is rendered as a transparent PNG using Flutter's own
  /// TextPainter + Canvas (the same Skia renderer used in the preview),
  /// then composited onto the video with FFmpeg's overlay filter.
  /// This produces pixel-perfect output matching the in-app preview.
  static Future<void> burnSubtitles({
    required String videoPath,
    required List<CaptionModel> captions,
    required CaptionStyleModel style,
    required String outputPath,
    void Function(double)? onProgress,
  }) async {
    await FileUtils.ensureDirectoryExists(outputPath);

    if (captions.isEmpty) {
      _log.w('No captions to burn, copying video as-is');
      await File(videoPath).copy(outputPath);
      return;
    }

    // Probe video resolution and bitrate
    final (videoWidth, videoHeight) = await _getVideoResolution(videoPath);

    // Render all caption images using Flutter's text engine
    _log.i('Rendering ${captions.length} caption images...');
    final captionImages = await CaptionImageRenderer.renderAll(
      captions: captions,
      style: style,
      videoWidth: videoWidth,
      videoHeight: videoHeight,
    );

    if (captionImages.isEmpty) {
      _log.w('No caption images rendered, copying video as-is');
      await File(videoPath).copy(outputPath);
      return;
    }

    // Probe original video bitrate to preserve quality
    final originalBitrate = await _getVideoBitrate(videoPath);
    final bitrateArgs = <String>[];
    if (originalBitrate != null) {
      final parsed = int.tryParse(originalBitrate);
      if (parsed != null) {
        bitrateArgs.addAll([
          '-b:v', '$parsed',
          '-maxrate', '$parsed',
          '-bufsize', '${parsed * 2}',
        ]);
      } else {
        bitrateArgs.addAll(['-crf', '17']);
      }
    } else {
      bitrateArgs.addAll(['-crf', '17']);
    }

    // Build FFmpeg command with chained overlay filters.
    // Each caption image is an input, overlaid at its (x,y) position
    // with an enable condition for its time window.
    final args = <String>['-y', '-i', videoPath];

    // Add each caption image as an input
    for (final img in captionImages) {
      args.addAll(['-i', img.imagePath]);
    }

    // Build filter_complex with chained overlays
    final filterParts = <String>[];
    for (var i = 0; i < captionImages.length; i++) {
      final img = captionImages[i];
      final startSec =
          (img.startTime.inMilliseconds / 1000.0).toStringAsFixed(3);
      final endSec =
          (img.endTime.inMilliseconds / 1000.0).toStringAsFixed(3);

      // Input label: [0] is video, [1]..[N] are caption images
      final inputLabel = i == 0 ? '[0]' : '[v$i]';
      final imgLabel = '[${i + 1}]';
      final outputLabel =
          i == captionImages.length - 1 ? '[vout]' : '[v${i + 1}]';

      filterParts.add(
        "$inputLabel${imgLabel}overlay=${img.x}:${img.y}"
        ":enable='between(t,$startSec,$endSec)'$outputLabel",
      );
    }

    final filterComplex = filterParts.join(';');

    args.addAll([
      '-filter_complex', filterComplex,
      '-map', '[vout]',
      '-map', '0:a?',
      '-c:v', 'libx264',
      '-preset', 'medium',
      ...bitrateArgs,
      '-c:a', 'copy',
      outputPath,
    ]);

    _log.i('Burning subtitles: ${captionImages.length} overlay images');

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

    final session = await FFmpegKit.executeWithArguments(args);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      _log.e('Subtitle burning failed: $logs');
      throw FFmpegException(
        command: 'burnSubtitles',
        returnCode: returnCode?.getValue(),
      );
    }

    // Clean up caption images
    try {
      for (final img in captionImages) {
        await File(img.imagePath).delete();
      }
    } catch (_) {}

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

    final filters = <String>[];
    final scaleFilter = settings.scaleFilter;
    if (scaleFilter != null) {
      filters.add(scaleFilter);
    }

    final args = [
      '-y',
      '-i', videoPath,
      if (filters.isNotEmpty) ...['-vf', filters.join(',')],
      '-c:v', 'libx264',
      '-preset', 'medium',
      '-crf', '17',
      '-b:v', settings.videoBitrate,
      '-maxrate', settings.videoBitrate,
      '-r', '${settings.fps}',
      '-c:a', 'copy',
      outputPath,
    ];

    _log.i('Compressing video: ${args.join(' ')}');

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

    final session = await FFmpegKit.executeWithArguments(args);
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
