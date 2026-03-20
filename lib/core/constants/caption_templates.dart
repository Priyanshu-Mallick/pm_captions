import 'package:flutter/material.dart';
import '../../data/models/caption_style_model.dart';

class CaptionTemplates {
  /// TikTok style: white bold text with yellow word highlight and black stroke.
  static const CaptionStyleModel tiktokStyle = CaptionStyleModel(
    fontFamily: 'Montserrat',
    fontSize: 26.0,
    fontWeight: FontWeight.w900,
    textColor: Colors.white,
    highlightColor: Color(0xFFFFD700),
    backgroundColor: Color(0x00000000),
    backgroundOpacity: 0.0,
    strokeColor: Colors.black,
    strokeWidth: 3.0,
    verticalPosition: 0.75,
    maxWordsPerLine: 4,
    animationStyle: CaptionAnimationStyle.karaoke,
    isAllCaps: true,
    predefinedTemplate: CaptionTemplate.tiktok,
  );

  /// YouTube style: white text with semi-transparent black background bar.
  static const CaptionStyleModel youtubeStyle = CaptionStyleModel(
    fontFamily: 'Roboto',
    fontSize: 20.0,
    fontWeight: FontWeight.w500,
    textColor: Colors.white,
    highlightColor: Color(0xFFFFD700),
    backgroundColor: Color(0xCC000000),
    backgroundOpacity: 0.8,
    backgroundBorderRadius: 4.0,
    strokeWidth: 0,
    verticalPosition: 0.9,
    maxWordsPerLine: 6,
    animationStyle: CaptionAnimationStyle.fadeIn,
    predefinedTemplate: CaptionTemplate.youtube,
  );

  /// Instagram style: stylish font with colorful gradient background pill.
  static const CaptionStyleModel instagramStyle = CaptionStyleModel(
    fontFamily: 'Raleway',
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    textColor: Colors.white,
    highlightColor: Color(0xFFFF6B6B),
    backgroundColor: Color(0xFFE94560),
    backgroundOpacity: 0.85,
    backgroundBorderRadius: 20.0,
    strokeWidth: 0,
    verticalPosition: 0.5,
    maxWordsPerLine: 4,
    animationStyle: CaptionAnimationStyle.slideUp,
    predefinedTemplate: CaptionTemplate.instagram,
  );

  /// Minimal style: small white text with subtle shadow.
  static const CaptionStyleModel minimalStyle = CaptionStyleModel(
    fontFamily: 'Poppins',
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    textColor: Colors.white,
    highlightColor: Color(0xFFFFD700),
    backgroundColor: Color(0x00000000),
    backgroundOpacity: 0,
    shadowBlur: 6.0,
    shadowColor: Color(0xCC000000),
    strokeWidth: 0,
    verticalPosition: 0.88,
    maxWordsPerLine: 6,
    animationStyle: CaptionAnimationStyle.fadeIn,
    predefinedTemplate: CaptionTemplate.minimal,
  );

  /// Bold style: very large bold text with thick black stroke.
  static const CaptionStyleModel boldStyle = CaptionStyleModel(
    fontFamily: 'Oswald',
    fontSize: 34.0,
    fontWeight: FontWeight.w900,
    textColor: Colors.white,
    highlightColor: Color(0xFFFF4757),
    backgroundColor: Color(0x00000000),
    backgroundOpacity: 0,
    strokeColor: Colors.black,
    strokeWidth: 4.0,
    verticalPosition: 0.7,
    maxWordsPerLine: 3,
    animationStyle: CaptionAnimationStyle.karaoke,
    isAllCaps: true,
    predefinedTemplate: CaptionTemplate.bold,
  );

  /// Neon style: glowing cyan/green text on dark background.
  static const CaptionStyleModel neonStyle = CaptionStyleModel(
    fontFamily: 'Montserrat',
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    textColor: Color(0xFF00FFE0),
    highlightColor: Color(0xFF00FF88),
    backgroundColor: Color(0xAA000000),
    backgroundOpacity: 0.7,
    backgroundBorderRadius: 8.0,
    shadowColor: Color(0xFF00FFE0),
    shadowBlur: 12.0,
    strokeWidth: 0,
    verticalPosition: 0.8,
    maxWordsPerLine: 5,
    animationStyle: CaptionAnimationStyle.fadeIn,
    predefinedTemplate: CaptionTemplate.neon,
  );

  /// Typewriter style: monospace font, character-by-character appearance.
  static const CaptionStyleModel typewriterStyle = CaptionStyleModel(
    fontFamily: 'Courier Prime',
    fontSize: 20.0,
    fontWeight: FontWeight.w400,
    textColor: Color(0xFFE0E0E0),
    highlightColor: Color(0xFFFFD700),
    backgroundColor: Color(0xBB000000),
    backgroundOpacity: 0.7,
    backgroundBorderRadius: 4.0,
    strokeWidth: 0,
    verticalPosition: 0.85,
    maxWordsPerLine: 6,
    animationStyle: CaptionAnimationStyle.typewriter,
    predefinedTemplate: CaptionTemplate.typewriter,
  );

  /// Returns the style for a given template.
  static CaptionStyleModel fromTemplate(CaptionTemplate template) {
    switch (template) {
      case CaptionTemplate.tiktok:
        return tiktokStyle;
      case CaptionTemplate.youtube:
        return youtubeStyle;
      case CaptionTemplate.instagram:
        return instagramStyle;
      case CaptionTemplate.minimal:
        return minimalStyle;
      case CaptionTemplate.bold:
        return boldStyle;
      case CaptionTemplate.neon:
        return neonStyle;
      case CaptionTemplate.typewriter:
        return typewriterStyle;
      case CaptionTemplate.defaultTemplate:
        return const CaptionStyleModel();
    }
  }
}
