import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../core/constants/caption_templates.dart';
import '../../data/models/caption_style_model.dart';

/// Manages caption styling configuration.
///
/// Provides methods to update individual style properties and
/// apply predefined templates.
class StyleProvider extends ChangeNotifier {
  static final _log = Logger();

  // ── State ─────────────────────────────────────────────────────────
  CaptionStyleModel _currentStyle = const CaptionStyleModel();

  /// All available templates.
  final List<CaptionTemplate> availableTemplates = CaptionTemplate.values;

  // ── Getters ───────────────────────────────────────────────────────
  CaptionStyleModel get currentStyle => _currentStyle;

  // ── Template Application ──────────────────────────────────────────

  /// Applies a predefined template.
  void applyTemplate(CaptionTemplate template) {
    _currentStyle = CaptionTemplates.fromTemplate(template);
    _log.i('Applied template: ${template.name}');
    notifyListeners();
  }

  /// Resets to default style.
  void resetToDefault() {
    _currentStyle = const CaptionStyleModel();
    notifyListeners();
  }

  /// Sets the full style (used when loading a project).
  void setStyle(CaptionStyleModel style) {
    _currentStyle = style;
    notifyListeners();
  }

  // ── Individual Property Updates ───────────────────────────────────

  void updateFontFamily(String font) {
    _currentStyle = _currentStyle.copyWith(fontFamily: font);
    notifyListeners();
  }

  void updateFontSize(double size) {
    _currentStyle = _currentStyle.copyWith(fontSize: size);
    notifyListeners();
  }

  void updateTextColor(Color color) {
    _currentStyle = _currentStyle.copyWith(textColor: color);
    notifyListeners();
  }

  void updateHighlightColor(Color color) {
    _currentStyle = _currentStyle.copyWith(highlightColor: color);
    notifyListeners();
  }

  void updateBackgroundColor(Color color) {
    _currentStyle = _currentStyle.copyWith(backgroundColor: color);
    notifyListeners();
  }

  void updateBackgroundOpacity(double opacity) {
    _currentStyle = _currentStyle.copyWith(backgroundOpacity: opacity);
    notifyListeners();
  }

  void updateBackgroundBorderRadius(double radius) {
    _currentStyle = _currentStyle.copyWith(backgroundBorderRadius: radius);
    notifyListeners();
  }

  void updatePosition(double verticalPosition) {
    _currentStyle = _currentStyle.copyWith(verticalPosition: verticalPosition);
    notifyListeners();
  }

  void updateStrokeColor(Color color) {
    _currentStyle = _currentStyle.copyWith(strokeColor: color);
    notifyListeners();
  }

  void updateStrokeWidth(double width) {
    _currentStyle = _currentStyle.copyWith(strokeWidth: width);
    notifyListeners();
  }

  void updateShadowBlur(double blur) {
    _currentStyle = _currentStyle.copyWith(shadowBlur: blur);
    notifyListeners();
  }

  void updateShadowColor(Color color) {
    _currentStyle = _currentStyle.copyWith(shadowColor: color);
    notifyListeners();
  }

  void updateMaxWordsPerLine(int words) {
    _currentStyle = _currentStyle.copyWith(maxWordsPerLine: words);
    notifyListeners();
  }

  void updateMaxLines(int lines) {
    _currentStyle = _currentStyle.copyWith(maxLines: lines);
    notifyListeners();
  }

  void updateAnimationStyle(CaptionAnimationStyle style) {
    _currentStyle = _currentStyle.copyWith(animationStyle: style);
    notifyListeners();
  }

  void toggleAllCaps() {
    _currentStyle = _currentStyle.copyWith(isAllCaps: !_currentStyle.isAllCaps);
    notifyListeners();
  }

  void updateFontWeight(FontWeight weight) {
    _currentStyle = _currentStyle.copyWith(fontWeight: weight);
    notifyListeners();
  }

  void updateTextAlign(TextAlign align) {
    _currentStyle = _currentStyle.copyWith(textAlign: align);
    notifyListeners();
  }
}
