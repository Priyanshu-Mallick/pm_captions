import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

/// Utility functions for file operations.
class FileUtils {
  FileUtils._();

  static final _log = Logger();

  /// Returns the application documents directory path.
  static Future<String> get appDocumentsPath async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Returns the temporary directory path.
  static Future<String> get tempPath async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }

  /// Creates a unique filename with the given extension in the temp directory.
  static Future<String> createTempFilePath(String extension) async {
    final temp = await tempPath;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(temp, 'ai_captions_$timestamp.$extension');
  }

  /// Creates a unique filename in the app documents directory.
  static Future<String> createOutputFilePath(String extension) async {
    final docs = await appDocumentsPath;
    final outputDir = Directory(p.join(docs, 'ai_captions_output'));
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(outputDir.path, 'caption_video_$timestamp.$extension');
  }

  /// Returns the file size in MB.
  static Future<double> getFileSizeMB(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final bytes = await file.length();
      return bytes / (1024 * 1024);
    }
    return 0;
  }

  /// Returns a human-readable file size string.
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Returns the file extension (lowercase, without dot).
  static String getExtension(String filePath) {
    return p.extension(filePath).replaceFirst('.', '').toLowerCase();
  }

  /// Checks if the file extension is a supported video format.
  static bool isSupportedVideoFormat(String filePath) {
    const supported = {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'};
    return supported.contains(getExtension(filePath));
  }

  /// Deletes a file if it exists.
  static Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      _log.w('Failed to delete file: $filePath', error: e);
    }
  }

  /// Copies a file to a new path.
  static Future<String> copyFile(String sourcePath, String destPath) async {
    final source = File(sourcePath);
    final destination = await source.copy(destPath);
    return destination.path;
  }

  /// Ensures the directory for the given file path exists.
  static Future<void> ensureDirectoryExists(String filePath) async {
    final dir = Directory(p.dirname(filePath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
}
