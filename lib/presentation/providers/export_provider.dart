import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/caption_model.dart';
import '../../data/models/caption_style_model.dart';
import '../../data/models/export_settings_model.dart';
import '../../data/repositories/export_repository.dart';

/// The current stage of export.
enum ExportState { idle, preparing, rendering, saving, done, error }

/// Manages video export operations and state.
class ExportProvider extends ChangeNotifier {
  static final _log = Logger();
  final ExportRepository _exportRepo;

  ExportProvider({ExportRepository? exportRepo})
    : _exportRepo = exportRepo ?? ExportRepository();

  // ── State ─────────────────────────────────────────────────────────
  ExportState _exportState = ExportState.idle;
  double _exportProgress = 0.0;
  String? _exportedFilePath;
  String? _srtFilePath;
  String? _vttFilePath;
  String? _errorMessage;
  bool _savedToGallery = false;
  bool get savedToGallery => _savedToGallery;

  // ── Getters ───────────────────────────────────────────────────────
  ExportState get exportState => _exportState;
  double get exportProgress => _exportProgress;
  String? get exportedFilePath => _exportedFilePath;
  String? get srtFilePath => _srtFilePath;
  String? get vttFilePath => _vttFilePath;
  String? get errorMessage => _errorMessage;

  bool get isExporting =>
      _exportState != ExportState.idle &&
      _exportState != ExportState.done &&
      _exportState != ExportState.error;

  // ── Export Methods ────────────────────────────────────────────────

  /// Exports the video with burned-in captions.
  Future<void> exportVideo({
    required String videoPath,
    required List<CaptionModel> captions,
    required CaptionStyleModel style,
    required ExportSettingsModel settings,
  }) async {
    try {
      _errorMessage = null;
      _updateState(ExportState.preparing, 0.05);

      // Export video with subtitles
      _updateState(ExportState.rendering, 0.1);

      _exportedFilePath = await _exportRepo.exportVideoWithSubtitles(
        videoPath: videoPath,
        captions: captions,
        style: style,
        settings: settings,
        onProgress: (progress) {
          _exportProgress = 0.1 + (progress * 0.8);
          notifyListeners();
        },
      );

      // Export SRT if requested
      if (settings.exportSRT) {
        _srtFilePath = await _exportRepo.exportSrt(captions);
      }

      // Export VTT if requested
      if (settings.exportVTT) {
        _vttFilePath = await _exportRepo.exportVtt(captions);
      }

      _updateState(ExportState.done, 1.0);
      _log.i('Export complete: $_exportedFilePath');
      // Auto-save to device gallery
      if (_exportedFilePath != null) {
        try {
          await GallerySaver.saveVideo(_exportedFilePath!);
          _savedToGallery = true;
          _log.i('Auto-saved to gallery');
        } catch (e) {
          _log.w('Auto-save to gallery failed', error: e);
        }
        notifyListeners();
      }
    } catch (e) {
      _log.e('Export failed', error: e);
      _errorMessage = 'Export failed. Please try again.';
      _updateState(ExportState.error, _exportProgress);
    }
  }

  /// Exports only the SRT file.
  Future<void> exportSRT(List<CaptionModel> captions) async {
    try {
      _updateState(ExportState.preparing, 0.5);
      _srtFilePath = await _exportRepo.exportSrt(captions);
      _updateState(ExportState.done, 1.0);
    } catch (e) {
      _errorMessage = 'SRT export failed.';
      _updateState(ExportState.error, 0);
    }
  }

  /// Exports only the VTT file.
  Future<void> exportVTT(List<CaptionModel> captions) async {
    try {
      _updateState(ExportState.preparing, 0.5);
      _vttFilePath = await _exportRepo.exportVtt(captions);
      _updateState(ExportState.done, 1.0);
    } catch (e) {
      _errorMessage = 'VTT export failed.';
      _updateState(ExportState.error, 0);
    }
  }

  /// Saves the exported video to the device gallery.
  Future<bool> saveToGallery() async {
    if (_exportedFilePath == null) return false;
    try {
      _updateState(ExportState.saving, 0.9);
      await GallerySaver.saveVideo(_exportedFilePath!);
      _updateState(ExportState.done, 1.0);
      _log.i('Saved to gallery');
      return true;
    } catch (e) {
      _log.e('Failed to save to gallery', error: e);
      return false;
    }
  }

  /// Shares the exported file via the system share sheet.
  Future<void> shareExported(BuildContext context) async {
    final paths = <XFile>[];
    if (_exportedFilePath != null) {
      paths.add(XFile(_exportedFilePath!));
    }
    if (_srtFilePath != null) {
      paths.add(XFile(_srtFilePath!));
    }
    if (paths.isNotEmpty) {
      final box = context.findRenderObject() as RenderBox?;
      final rect =
          box != null ? box.localToGlobal(Offset.zero) & box.size : null;
      await Share.shareXFiles(
        paths,
        text: 'Video with AI Captions',
        sharePositionOrigin: rect,
      );
    }
  }

  /// Resets all export state.
  void reset() {
    _exportState = ExportState.idle;
    _exportProgress = 0.0;
    _exportedFilePath = null;
    _srtFilePath = null;
    _vttFilePath = null;
    _errorMessage = null;
    _savedToGallery = false;
    notifyListeners();
  }

  void _updateState(ExportState state, double progress) {
    _exportState = state;
    _exportProgress = progress;
    notifyListeners();
  }
}
