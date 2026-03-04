import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:video_player/video_player.dart';

import '../../core/utils/ffmpeg_utils.dart';
import '../../data/datasources/gallery_datasource.dart';

/// Manages video selection, playback, and state.
class VideoProvider extends ChangeNotifier {
  static final _log = Logger();
  final GalleryDatasource _galleryDatasource;

  VideoProvider({GalleryDatasource? galleryDatasource})
    : _galleryDatasource = galleryDatasource ?? GalleryDatasource();

  // ── State ─────────────────────────────────────────────────────────
  String? _selectedVideoPath;
  VideoPlayerController? _videoController;
  Duration _videoDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;
  String? _thumbnailPath;
  bool _isInitialized = false;

  // ── Getters ───────────────────────────────────────────────────────
  String? get selectedVideoPath => _selectedVideoPath;
  VideoPlayerController? get videoController => _videoController;
  Duration get videoDuration => _videoDuration;
  Duration get currentPosition => _currentPosition;
  bool get isPlaying => _isPlaying;
  String? get thumbnailPath => _thumbnailPath;
  bool get isInitialized => _isInitialized;
  bool get hasVideo => _selectedVideoPath != null;

  // ── Methods ───────────────────────────────────────────────────────

  /// Picks a video from the device gallery.
  Future<bool> pickVideoFromGallery() async {
    final path = await _galleryDatasource.pickVideoFromGallery();
    if (path != null) {
      await initializeVideo(path);
      return true;
    }
    return false;
  }

  /// Records a video using the camera.
  Future<bool> pickVideoFromCamera() async {
    final path = await _galleryDatasource.pickVideoFromCamera();
    if (path != null) {
      await initializeVideo(path);
      return true;
    }
    return false;
  }

  /// Initializes the video player with the given file path.
  Future<void> initializeVideo(String path) async {
    _log.i('Initializing video: $path');

    // Dispose existing controller
    await _disposeController();

    _selectedVideoPath = path;
    _isInitialized = false;
    notifyListeners();

    try {
      _videoController = VideoPlayerController.file(File(path));
      await _videoController!.initialize();
      _videoDuration = _videoController!.value.duration;
      _isInitialized = true;

      // Listen for position changes
      _videoController!.addListener(_onVideoPositionChanged);

      // Generate thumbnail
      _thumbnailPath = await FFmpegUtils.generateThumbnail(path);

      _log.i('Video initialized: duration=$_videoDuration');
      notifyListeners();
    } catch (e) {
      _log.e('Failed to initialize video', error: e);
      _isInitialized = false;
      notifyListeners();
    }
  }

  /// Handles video position updates.
  void _onVideoPositionChanged() {
    if (_videoController == null) return;
    final position = _videoController!.value.position;
    final playing = _videoController!.value.isPlaying;

    if (position != _currentPosition || playing != _isPlaying) {
      _currentPosition = position;
      _isPlaying = playing;
      notifyListeners();
    }
  }

  /// Starts video playback.
  Future<void> play() async {
    await _videoController?.play();
    _isPlaying = true;
    notifyListeners();
  }

  /// Pauses video playback.
  Future<void> pause() async {
    await _videoController?.pause();
    _isPlaying = false;
    notifyListeners();
  }

  /// Toggles play/pause.
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Seeks to a specific position.
  Future<void> seekTo(Duration position) async {
    await _videoController?.seekTo(position);
    _currentPosition = position;
    notifyListeners();
  }

  /// Generates a thumbnail image from the video without fully mounting playback.
  Future<String?> generateThumbnail(String path) async {
    try {
      return await FFmpegUtils.generateThumbnail(path);
    } catch (e) {
      _log.w('Failed to generate thumbnail silently for $path', error: e);
      return null;
    }
  }

  /// Disposes the current video controller.
  Future<void> _disposeController() async {
    _videoController?.removeListener(_onVideoPositionChanged);
    await _videoController?.dispose();
    _videoController = null;
    _isPlaying = false;
    _currentPosition = Duration.zero;
  }

  /// Resets all state.
  Future<void> reset() async {
    await _disposeController();
    _selectedVideoPath = null;
    _videoDuration = Duration.zero;
    _thumbnailPath = null;
    _isInitialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }
}
