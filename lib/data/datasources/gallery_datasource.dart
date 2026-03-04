import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';

/// Datasource for picking media files from the device.
class GalleryDatasource {
  static final _log = Logger();
  final ImagePicker _imagePicker;

  GalleryDatasource({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  /// Picks a video from the device gallery.
  ///
  /// Returns the file path or `null` if cancelled.
  Future<String?> pickVideoFromGallery() async {
    try {
      final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        _log.i('Video picked from gallery: ${video.path}');
        return video.path;
      }
      return null;
    } catch (e) {
      _log.e('Failed to pick video from gallery', error: e);
      return null;
    }
  }

  /// Records a video using the device camera.
  ///
  /// Returns the file path or `null` if cancelled.
  Future<String?> pickVideoFromCamera() async {
    try {
      final video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10),
      );
      if (video != null) {
        _log.i('Video recorded from camera: ${video.path}');
        return video.path;
      }
      return null;
    } catch (e) {
      _log.e('Failed to record video from camera', error: e);
      return null;
    }
  }

  /// Picks an SRT file from the device.
  ///
  /// Returns the file path or `null` if cancelled.
  Future<String?> pickSrtFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['srt', 'vtt'],
      );
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        _log.i('SRT file picked: $path');
        return path;
      }
      return null;
    } catch (e) {
      _log.e('Failed to pick SRT file', error: e);
      return null;
    }
  }
}
