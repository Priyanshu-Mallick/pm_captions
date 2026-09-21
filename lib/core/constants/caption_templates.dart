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

  // ---------------------------------------------------------------------
  // Pro styles
  //
  // All Pro styles use karaoke animation: it is the word-highlight look these
  // styles are selling, and it is the only animation the export renderer
  // reproduces (everything else flattens to a static image in the MP4).
  //
  // Fonts must be bundled in google_fonts/ — runtime fetching is disabled in
  // main.dart, so an unbundled family silently falls back to the system font.
  // Anton, Bebas Neue and Bangers ship a Regular weight only, so their presets
  // use w400 rather than asking for a weight that isn't in the file.
  //
  // What makes these Pro rather than recoloured free styles is the highlight
  // mechanic: box blocks and hard scale pops are render-time behaviours the
  // free presets have no field for.
  // ---------------------------------------------------------------------

  /// Karaoke Box style: a solid block snaps behind each word as it is spoken.
  ///
  /// This is the mechanic free styles cannot reproduce — they can only recolour
  /// the active word. Uses Anton, whose heavy condensed caps sit well inside a
  /// tight block.
  static const CaptionStyleModel karaokeBoxStyle = CaptionStyleModel(
    fontFamily: 'Anton',
    fontSize: 26.0,
    fontWeight: FontWeight.w400,
    textColor: Color(0xFFFFFFFF),
    // In box mode highlightColor becomes the block, not the glyphs.
    highlightColor: Color(0xFF1FE06A),
    highlightTextColor: Color(0xFF07160D),
    wordHighlightMode: CaptionWordHighlight.box,
    activeWordScale: 1.0,
    backgroundColor: Color(0x00000000),
    backgroundOpacity: 0.0,
    backgroundBorderRadius: 0.0,
    shadowColor: Color(0xFF000000),
    shadowBlur: 5.0,
    shadowOffsetY: 2.0,
    strokeColor: Color(0xFF000000),
    strokeWidth: 2.5,
    letterSpacing: 0.5,
    verticalPosition: 0.76,
    maxWordsPerLine: 3,
    isAllCaps: true,
    maxLines: 2,
    animationStyle: CaptionAnimationStyle.karaoke,
    predefinedTemplate: CaptionTemplate.karaokeBox,
  );

  /// Hormozi style: condensed uppercase with electric lime highlight.
  static const CaptionStyleModel hormoziStyle = CaptionStyleModel(
    fontFamily: 'Bebas Neue',
    fontSize: 30.0,
    fontWeight: FontWeight.w400,
    textColor: Color(0xFFFFFFFF),
    highlightColor: Color(0xFFCCFF00),
    backgroundColor: Color(0x00000000),
    backgroundOpacity: 0.0,
    backgroundBorderRadius: 0.0,
    shadowColor: Color(0xFF000000),
    shadowBlur: 4.0,
    shadowOffsetY: 2.0,
    strokeColor: Color(0xFF000000),
    strokeWidth: 2.5,
    letterSpacing: 0.5,
    verticalPosition: 0.8,
    maxWordsPerLine: 3,
    isAllCaps: true,
    maxLines: 2,
    animationStyle: CaptionAnimationStyle.karaoke,
    predefinedTemplate: CaptionTemplate.hormozi,
  );

  /// Cyberpunk style: magenta-to-cyan gradient text with a neon glow.
  static const CaptionStyleModel cyberpunkStyle = CaptionStyleModel(
    fontFamily: 'Poppins',
    fontSize: 24.0,
    fontWeight: FontWeight.w800,
    textColor: Color(0xFFFF2BD1),
    highlightColor: Color(0xFF00F0FF),
    gradientColors: [Color(0xFFFF2BD1), Color(0xFF00F0FF)],
    backgroundColor: Color(0xFF1A0033),
    backgroundOpacity: 0.55,
    backgroundBorderRadius: 6.0,
    shadowColor: Color(0xFF00F0FF),
    shadowBlur: 14.0,
    strokeWidth: 0,
    letterSpacing: 1.0,
    verticalPosition: 0.8,
    maxWordsPerLine: 4,
    isAllCaps: true,
    animationStyle: CaptionAnimationStyle.karaoke,
    predefinedTemplate: CaptionTemplate.cyberpunk,
  );

  /// Word Pop style: the spoken word scales up hard, mid-screen.
  ///
  /// Free styles are locked to the stock 1.05 bump, so the aggressive pop is
  /// only available here. Sits higher up the frame than the bottom-anchored
  /// free styles to leave room for the enlarged word.
  static const CaptionStyleModel wordPopStyle = CaptionStyleModel(
    fontFamily: 'Poppins',
    fontSize: 23.0,
    fontWeight: FontWeight.w900,
    textColor: Color(0xFFFFFFFF),
    highlightColor: Color(0xFFFF3D6E),
    activeWordScale: 1.4,
    backgroundColor: Color(0x00000000),
    backgroundOpacity: 0.0,
    backgroundBorderRadius: 0.0,
    shadowColor: Color(0xCC000000),
    shadowBlur: 8.0,
    shadowOffsetY: 3.0,
    strokeColor: Color(0xFF000000),
    strokeWidth: 2.0,
    verticalPosition: 0.6,
    maxWordsPerLine: 3,
    isAllCaps: true,
    maxLines: 2,
    animationStyle: CaptionAnimationStyle.karaoke,
    predefinedTemplate: CaptionTemplate.wordPop,
  );

  /// Comic Impact style: pop-art lettering with a hard offset drop shadow.
  static const CaptionStyleModel comicImpactStyle = CaptionStyleModel(
    fontFamily: 'Bangers',
    fontSize: 30.0,
    fontWeight: FontWeight.w400,
    textColor: Color(0xFFFFFFFF),
    highlightColor: Color(0xFFFF5A1F),
    backgroundColor: Color(0x00000000),
    backgroundOpacity: 0.0,
    backgroundBorderRadius: 0.0,
    shadowColor: Color(0xFF111111),
    shadowBlur: 0.0,
    shadowOffsetX: 4.0,
    shadowOffsetY: 4.0,
    strokeColor: Color(0xFF111111),
    strokeWidth: 2.0,
    letterSpacing: 1.0,
    verticalPosition: 0.78,
    maxWordsPerLine: 4,
    isAllCaps: true,
    animationStyle: CaptionAnimationStyle.karaoke,
    predefinedTemplate: CaptionTemplate.comicImpact,
  );

  /// Frosted Glass style: translucent light pill with a soft bordered edge.
  static const CaptionStyleModel frostedGlassStyle = CaptionStyleModel(
    fontFamily: 'Poppins',
    fontSize: 22.0,
    fontWeight: FontWeight.w500,
    textColor: Color(0xFFFFFFFF),
    highlightColor: Color(0xFF9EE8FF),
    backgroundColor: Color(0xFFFFFFFF),
    backgroundOpacity: 0.18,
    backgroundBorderRadius: 28.0,
    borderColor: Color(0x66FFFFFF),
    borderWidth: 1.0,
    shadowColor: Color(0x99000000),
    shadowBlur: 10.0,
    strokeWidth: 0,
    letterSpacing: 0.3,
    horizontalPadding: 20.0,
    verticalPosition: 0.82,
    maxWordsPerLine: 5,
    animationStyle: CaptionAnimationStyle.karaoke,
    predefinedTemplate: CaptionTemplate.frostedGlass,
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
      case CaptionTemplate.karaokeBox:
        return karaokeBoxStyle;
      case CaptionTemplate.hormozi:
        return hormoziStyle;
      case CaptionTemplate.cyberpunk:
        return cyberpunkStyle;
      case CaptionTemplate.wordPop:
        return wordPopStyle;
      case CaptionTemplate.comicImpact:
        return comicImpactStyle;
      case CaptionTemplate.frostedGlass:
        return frostedGlassStyle;
      case CaptionTemplate.defaultTemplate:
        return const CaptionStyleModel();
    }
  }
}
