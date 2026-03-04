import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Animation styles available for caption display.
enum CaptionAnimationStyle { none, fadeIn, slideUp, typewriter, karaoke }

/// Pre-defined caption templates.
enum CaptionTemplate {
  defaultTemplate,
  tiktok,
  youtube,
  instagram,
  minimal,
  bold,
  neon,
  typewriter,
}

/// Model representing caption styling options.
///
/// Includes font, color, position, animation, and background settings.
/// Can be converted to FFmpeg subtitle filter style strings.
class CaptionStyleModel extends Equatable {
  final String fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;
  final Color highlightColor;
  final Color backgroundColor;
  final double backgroundOpacity;
  final double backgroundBorderRadius;
  final Color shadowColor;
  final double shadowBlur;
  final Color strokeColor;
  final double strokeWidth;
  final TextAlign textAlign;
  final double verticalPosition;
  final double horizontalPadding;
  final double lineSpacing;
  final int maxWordsPerLine;
  final CaptionAnimationStyle animationStyle;
  final bool isAllCaps;
  final int maxLines;
  final CaptionTemplate predefinedTemplate;

  const CaptionStyleModel({
    this.fontFamily = 'Montserrat',
    this.fontSize = 22.0,
    this.fontWeight = FontWeight.w700,
    this.textColor = Colors.white,
    this.highlightColor = const Color(0xFFFFD700),
    this.backgroundColor = const Color(0x99000000),
    this.backgroundOpacity = 0.6,
    this.backgroundBorderRadius = 8.0,
    this.shadowColor = Colors.black,
    this.shadowBlur = 4.0,
    this.strokeColor = Colors.black,
    this.strokeWidth = 1.5,
    this.textAlign = TextAlign.center,
    this.verticalPosition = 0.85,
    this.horizontalPadding = 16.0,
    this.lineSpacing = 1.2,
    this.maxWordsPerLine = 5,
    this.animationStyle = CaptionAnimationStyle.karaoke,
    this.isAllCaps = false,
    this.maxLines = 2,
    this.predefinedTemplate = CaptionTemplate.defaultTemplate,
  });

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

  /// Creates a [CaptionStyleModel] from a JSON map.
  factory CaptionStyleModel.fromJson(Map<String, dynamic> json) {
    return CaptionStyleModel(
      fontFamily: json['fontFamily'] as String? ?? 'Montserrat',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 22.0,
      fontWeight: FontWeight.values[json['fontWeight'] as int? ?? 7],
      textColor: Color(json['textColor'] as int? ?? 0xFFFFFFFF),
      highlightColor: Color(json['highlightColor'] as int? ?? 0xFFFFD700),
      backgroundColor: Color(json['backgroundColor'] as int? ?? 0x99000000),
      backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble() ?? 0.6,
      backgroundBorderRadius:
          (json['backgroundBorderRadius'] as num?)?.toDouble() ?? 8.0,
      shadowColor: Color(json['shadowColor'] as int? ?? 0xFF000000),
      shadowBlur: (json['shadowBlur'] as num?)?.toDouble() ?? 4.0,
      strokeColor: Color(json['strokeColor'] as int? ?? 0xFF000000),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 1.5,
      textAlign:
          TextAlign.values[json['textAlign'] as int? ?? TextAlign.center.index],
      verticalPosition: (json['verticalPosition'] as num?)?.toDouble() ?? 0.85,
      horizontalPadding:
          (json['horizontalPadding'] as num?)?.toDouble() ?? 16.0,
      lineSpacing: (json['lineSpacing'] as num?)?.toDouble() ?? 1.2,
      maxWordsPerLine: json['maxWordsPerLine'] as int? ?? 5,
      animationStyle:
          CaptionAnimationStyle.values[json['animationStyle'] as int? ??
              CaptionAnimationStyle.karaoke.index],
      isAllCaps: json['isAllCaps'] as bool? ?? false,
      maxLines: json['maxLines'] as int? ?? 2,
      predefinedTemplate:
          CaptionTemplate.values[json['predefinedTemplate'] as int? ??
              CaptionTemplate.defaultTemplate.index],
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'fontWeight': fontWeight.index,
      'textColor': textColor.value,
      'highlightColor': highlightColor.value,
      'backgroundColor': backgroundColor.value,
      'backgroundOpacity': backgroundOpacity,
      'backgroundBorderRadius': backgroundBorderRadius,
      'shadowColor': shadowColor.value,
      'shadowBlur': shadowBlur,
      'strokeColor': strokeColor.value,
      'strokeWidth': strokeWidth,
      'textAlign': textAlign.index,
      'verticalPosition': verticalPosition,
      'horizontalPadding': horizontalPadding,
      'lineSpacing': lineSpacing,
      'maxWordsPerLine': maxWordsPerLine,
      'animationStyle': animationStyle.index,
      'isAllCaps': isAllCaps,
      'maxLines': maxLines,
      'predefinedTemplate': predefinedTemplate.index,
    };
  }

  /// Serializes the style to a JSON string for database storage.
  String toJsonString() => jsonEncode(toJson());

  /// Deserializes a style from a JSON string.
  factory CaptionStyleModel.fromJsonString(String jsonString) {
    return CaptionStyleModel.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  /// Creates a copy with the given fields replaced.
  CaptionStyleModel copyWith({
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    Color? textColor,
    Color? highlightColor,
    Color? backgroundColor,
    double? backgroundOpacity,
    double? backgroundBorderRadius,
    Color? shadowColor,
    double? shadowBlur,
    Color? strokeColor,
    double? strokeWidth,
    TextAlign? textAlign,
    double? verticalPosition,
    double? horizontalPadding,
    double? lineSpacing,
    int? maxWordsPerLine,
    CaptionAnimationStyle? animationStyle,
    bool? isAllCaps,
    int? maxLines,
    CaptionTemplate? predefinedTemplate,
  }) {
    return CaptionStyleModel(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      textColor: textColor ?? this.textColor,
      highlightColor: highlightColor ?? this.highlightColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      backgroundBorderRadius:
          backgroundBorderRadius ?? this.backgroundBorderRadius,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      textAlign: textAlign ?? this.textAlign,
      verticalPosition: verticalPosition ?? this.verticalPosition,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      maxWordsPerLine: maxWordsPerLine ?? this.maxWordsPerLine,
      animationStyle: animationStyle ?? this.animationStyle,
      isAllCaps: isAllCaps ?? this.isAllCaps,
      maxLines: maxLines ?? this.maxLines,
      predefinedTemplate: predefinedTemplate ?? this.predefinedTemplate,
    );
  }

  // ── Predefined Templates ────────────────────────────────────────

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

  @override
  List<Object?> get props => [
    fontFamily,
    fontSize,
    fontWeight,
    textColor,
    highlightColor,
    backgroundColor,
    backgroundOpacity,
    backgroundBorderRadius,
    shadowColor,
    shadowBlur,
    strokeColor,
    strokeWidth,
    textAlign,
    verticalPosition,
    horizontalPadding,
    lineSpacing,
    maxWordsPerLine,
    animationStyle,
    isAllCaps,
    maxLines,
    predefinedTemplate,
  ];
}
