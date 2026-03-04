import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

import '../errors/exceptions.dart';

/// Utility class for managing runtime permissions.
class PermissionUtils {
  PermissionUtils._();

  static final _log = Logger();

  /// Requests storage permissions (handles Android 13+ media permissions).
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ uses granular media permissions
      final videoStatus = await Permission.videos.request();
      final audioStatus = await Permission.audio.request();
      if (videoStatus.isGranted || audioStatus.isGranted) return true;

      // Fallback for older Android
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } else if (Platform.isIOS) {
      final photosStatus = await Permission.photos.request();
      return photosStatus.isGranted || photosStatus.isLimited;
    }
    return true;
  }

  /// Requests camera permission.
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Requests microphone permission.
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Requests all permissions needed by the app.
  static Future<bool> requestAllPermissions() async {
    final storage = await requestStoragePermission();
    final camera = await requestCameraPermission();
    final mic = await requestMicrophonePermission();
    _log.i('Permissions: storage=$storage, camera=$camera, mic=$mic');
    return storage;
  }

  /// Ensures storage permission is granted, throws if denied.
  static Future<void> ensureStoragePermission() async {
    final granted = await requestStoragePermission();
    if (!granted) {
      throw PermissionDeniedException(permission: 'storage');
    }
  }

  /// Opens the device app settings page.
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
