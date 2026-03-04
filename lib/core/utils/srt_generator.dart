import 'dart:io';

import 'package:logger/logger.dart';

import '../../data/models/caption_model.dart';
import 'file_utils.dart';
import 'time_formatter.dart';

/// Generator for SRT and VTT subtitle files.
///
/// Converts [CaptionModel] lists into standard subtitle file formats
/// and also provides parsing from SRT content back to [CaptionModel].
class SrtGenerator {
  SrtGenerator._();

  static final _log = Logger();

  /// Generates an SRT subtitle file from a list of captions.
  ///
  /// Returns the path to the generated SRT file.
  static Future<String> generateSrt(List<CaptionModel> captions) async {
    final buffer = StringBuffer();

    for (var i = 0; i < captions.length; i++) {
      final caption = captions[i];
      final index = i + 1;
      final startStr = TimeFormatter.durationToSrt(caption.startTime);
      final endStr = TimeFormatter.durationToSrt(caption.endTime);

      buffer.writeln(index);
      buffer.writeln('$startStr --> $endStr');
      buffer.writeln(caption.text);
      buffer.writeln();
    }

    final outputPath = await FileUtils.createTempFilePath('srt');
    final file = File(outputPath);
    await file.writeAsString(buffer.toString());

    _log.i('SRT generated at: $outputPath');
    return outputPath;
  }

  /// Generates a VTT subtitle file from a list of captions.
  ///
  /// Returns the path to the generated VTT file.
  static Future<String> generateVtt(List<CaptionModel> captions) async {
    final buffer = StringBuffer();
    buffer.writeln('WEBVTT');
    buffer.writeln();

    for (var i = 0; i < captions.length; i++) {
      final caption = captions[i];
      final startStr = TimeFormatter.durationToVtt(caption.startTime);
      final endStr = TimeFormatter.durationToVtt(caption.endTime);

      buffer.writeln('${i + 1}');
      buffer.writeln('$startStr --> $endStr');
      buffer.writeln(caption.text);
      buffer.writeln();
    }

    final outputPath = await FileUtils.createTempFilePath('vtt');
    final file = File(outputPath);
    await file.writeAsString(buffer.toString());

    _log.i('VTT generated at: $outputPath');
    return outputPath;
  }

  /// Parses an SRT file content into a list of [CaptionModel].
  ///
  /// Supports importing existing SRT files for editing.
  static List<CaptionModel> parseSrt(String content) {
    final captions = <CaptionModel>[];
    final blocks = content
        .trim()
        .split(RegExp(r'\r?\n\r?\n'))
        .where((b) => b.trim().isNotEmpty);

    for (final block in blocks) {
      final lines = block.trim().split(RegExp(r'\r?\n'));
      if (lines.length < 3) continue;

      // lines[0] = index number
      // lines[1] = timestamp range
      // lines[2..] = text
      final timeParts = lines[1].split('-->');
      if (timeParts.length != 2) continue;

      final startDuration = _parseSrtTimestamp(timeParts[0].trim());
      final endDuration = _parseSrtTimestamp(timeParts[1].trim());

      if (startDuration == null || endDuration == null) continue;

      final text = lines.sublist(2).join(' ').trim();

      captions.add(
        CaptionModel.create(
          text: text,
          words: [], // No word-level data from SRT import
          startTime: startDuration,
          endTime: endDuration,
        ),
      );
    }

    _log.i('Parsed ${captions.length} captions from SRT');
    return captions;
  }

  /// Parses an SRT timestamp string like "00:01:02,345" into a [Duration].
  static Duration? _parseSrtTimestamp(String timestamp) {
    try {
      // Format: HH:MM:SS,mmm
      final mainParts = timestamp.split(',');
      if (mainParts.length != 2) {
        // Try VTT format with dot
        final vttParts = timestamp.split('.');
        if (vttParts.length != 2) return null;
        return _parseTimeParts(vttParts[0], int.parse(vttParts[1]));
      }

      final milliseconds = int.parse(mainParts[1]);
      return _parseTimeParts(mainParts[0], milliseconds);
    } catch (e) {
      _log.w('Failed to parse SRT timestamp: $timestamp', error: e);
      return null;
    }
  }

  /// Helper to parse "HH:MM:SS" + milliseconds into a [Duration].
  static Duration? _parseTimeParts(String timePart, int milliseconds) {
    final parts = timePart.split(':');
    if (parts.length != 3) return null;

    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(parts[2]);

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }
}
