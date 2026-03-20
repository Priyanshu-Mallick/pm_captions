import 'package:flutter/material.dart';

import '../../data/models/caption_style_model.dart';

extension CaptionStyleFFmpegExtension on CaptionStyleModel {
  /// Converts this style to an FFmpeg `force_style` string for ASS/SSA subtitles.
  ///
  /// FFmpeg uses AABBGGRR color format (alpha, blue, green, red).
  String toFFmpegStyle() {
    final fontName = fontFamily;
    final fSize = fontSize.round();
    final primaryColor = _colorToFFmpegHex(textColor);
    final outlineColor = _colorToFFmpegHex(strokeColor);
    final shadowCol = _colorToFFmpegHex(shadowColor);
    final isBold = fontWeight.index >= FontWeight.w700.index ? 1 : 0;
    final outline = strokeWidth.round();
    final shadow = shadowBlur > 0 ? 1 : 0;
    final alignment = _textAlignToSSA(textAlign);
    final marginV = ((1.0 - verticalPosition) * 100).round();

    return "FontName=$fontName,FontSize=$fSize,"
        "PrimaryColour=$primaryColor,Bold=$isBold,"
        "Outline=$outline,OutlineColour=$outlineColor,"
        "Shadow=$shadow,ShadowColour=$shadowCol,"
        "Alignment=$alignment,MarginV=$marginV";
  }

  /// Converts a Flutter [Color] to FFmpeg hex format (AABBGGRR).
  String _colorToFFmpegHex(Color color) {
    final a = (255 - color.alpha).toRadixString(16).padLeft(2, '0');
    final b = color.blue.toRadixString(16).padLeft(2, '0');
    final g = color.green.toRadixString(16).padLeft(2, '0');
    final r = color.red.toRadixString(16).padLeft(2, '0');
    return '&H$a$b$g$r';
  }

  /// Maps [TextAlign] to SSA/ASS alignment values.
  int _textAlignToSSA(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return 1;
      case TextAlign.center:
        return 2;
      case TextAlign.right:
        return 3;
      default:
        return 2;
    }
  }
}
