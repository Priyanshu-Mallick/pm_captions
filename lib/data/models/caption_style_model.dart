import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Animation styles available for caption display.
enum CaptionAnimationStyle { none, fadeIn, slideUp, typewriter, karaoke }

/// How the currently-spoken word is emphasised during karaoke playback.
///
/// This is the mechanic that separates caption styles in practice: recolouring
/// the word is the baseline every editor can do, while a block behind the word
/// is the look that dominates short-form feeds.
///
/// Persisted by index — append only.
enum CaptionWordHighlight {
  /// Recolour the active word with `highlightColor`.
  color,

  /// Paint a solid `highlightColor` block behind the active word.
  box,
}

/// Pre-defined caption templates.
///
/// IMPORTANT: values are persisted by [Enum.index] (see [CaptionStyleModel.toJson]),
/// so new templates must be APPENDED only. Inserting or reordering silently
/// remaps the template of every already-saved project.
enum CaptionTemplate {
  // Free
  defaultTemplate,
  tiktok,
  youtube,
  instagram,
  minimal,
  bold,
  neon,
  typewriter,
  // Pro — append only.
  karaokeBox,
  hormozi,
  cyberpunk,
  wordPop,
  comicImpact,
  frostedGlass,
}

/// Display metadata and Pro gating for [CaptionTemplate].
extension CaptionTemplateInfo on CaptionTemplate {
  /// Whether this template requires an active Pro subscription to export.
  ///
  /// Relies on Pro templates being appended after the free ones.
  bool get isPro => index >= CaptionTemplate.karaokeBox.index;

  /// UI-friendly title.
  String get displayName => switch (this) {
    CaptionTemplate.defaultTemplate => 'Default',
    CaptionTemplate.tiktok => 'TikTok',
    CaptionTemplate.youtube => 'YouTube',
    CaptionTemplate.instagram => 'Instagram',
    CaptionTemplate.minimal => 'Minimal',
    CaptionTemplate.bold => 'Bold',
    CaptionTemplate.neon => 'Neon',
    CaptionTemplate.typewriter => 'Typewriter',
    CaptionTemplate.karaokeBox => 'Karaoke Box',
    CaptionTemplate.hormozi => 'Hormozi',
    CaptionTemplate.cyberpunk => 'Cyberpunk',
    CaptionTemplate.wordPop => 'Word Pop',
    CaptionTemplate.comicImpact => 'Comic',
    CaptionTemplate.frostedGlass => 'Frosted',
  };

  /// Short subtitle shown under the template name.
  String get description => switch (this) {
    CaptionTemplate.defaultTemplate => 'Clean and neutral',
    CaptionTemplate.tiktok => 'Punchy short-form',
    CaptionTemplate.youtube => 'Classic readable',
    CaptionTemplate.instagram => 'Soft and modern',
    CaptionTemplate.minimal => 'Understated text',
    CaptionTemplate.bold => 'Heavy condensed',
    CaptionTemplate.neon => 'Glowing accent',
    CaptionTemplate.typewriter => 'Monospace retro',
    CaptionTemplate.karaokeBox => 'Block behind each spoken word',
    CaptionTemplate.hormozi => 'Business hook retention',
    CaptionTemplate.cyberpunk => 'Neon tech and gaming',
    CaptionTemplate.wordPop => 'Spoken word scales up big',
    CaptionTemplate.comicImpact => 'Pop-art comic punch',
    CaptionTemplate.frostedGlass => 'Sleek frosted modern',
  };
}

/// Safely reads an index-based enum value from persisted JSON.
///
/// Guards against a saved index that no longer exists (e.g. the user downgrades
/// after saving a project that used a newer template).
T _enumFromIndex<T>(List<T> values, Object? raw, T fallback) {
  final index = raw is int ? raw : null;
  if (index == null || index < 0 || index >= values.length) return fallback;
  return values[index];
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

  /// Extra tracking between glyphs, in logical pixels.
  final double letterSpacing;

  /// Drop-shadow displacement. Zero keeps the shadow centred behind the text.
  final double shadowOffsetX;
  final double shadowOffsetY;

  /// Two or more colors paint the text with a horizontal gradient instead of
  /// the solid [textColor]. Null (or fewer than 2 colors) means solid.
  final List<Color>? gradientColors;

  /// Outline drawn around the background pill. Null or zero width means none.
  final Color? borderColor;
  final double borderWidth;

  /// How the active karaoke word is emphasised.
  final CaptionWordHighlight wordHighlightMode;

  /// Font-size multiplier applied to the active karaoke word.
  ///
  /// 1.0 disables the pop; values around 1.3 give the punchy "scale" look.
  final double activeWordScale;

  /// Text colour for the active word.
  ///
  /// Mainly needed in [CaptionWordHighlight.box] mode, where the accent colour
  /// becomes the block and the glyphs need to contrast against it (e.g. black
  /// text on a yellow block). Null falls back to a sensible per-mode default.
  final Color? highlightTextColor;

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
    this.letterSpacing = 0.0,
    this.shadowOffsetX = 0.0,
    this.shadowOffsetY = 0.0,
    this.gradientColors,
    this.borderColor,
    this.borderWidth = 0.0,
    this.wordHighlightMode = CaptionWordHighlight.color,
    this.activeWordScale = 1.05,
    this.highlightTextColor,
  });

  /// Whether the text should be painted with a gradient shader.
  bool get hasGradient =>
      gradientColors != null && gradientColors!.length >= 2;

  /// Whether the background pill should be outlined.
  bool get hasBorder => borderColor != null && borderWidth > 0;

  /// Creates a [CaptionStyleModel] from a JSON map.
  factory CaptionStyleModel.fromJson(Map<String, dynamic> json) {
    return CaptionStyleModel(
      fontFamily: json['fontFamily'] as String? ?? 'Montserrat',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 22.0,
      fontWeight: _enumFromIndex(
        FontWeight.values,
        json['fontWeight'],
        FontWeight.w700,
      ),
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
      textAlign: _enumFromIndex(
        TextAlign.values,
        json['textAlign'],
        TextAlign.center,
      ),
      verticalPosition: (json['verticalPosition'] as num?)?.toDouble() ?? 0.85,
      horizontalPadding:
          (json['horizontalPadding'] as num?)?.toDouble() ?? 16.0,
      lineSpacing: (json['lineSpacing'] as num?)?.toDouble() ?? 1.2,
      maxWordsPerLine: json['maxWordsPerLine'] as int? ?? 5,
      animationStyle: _enumFromIndex(
        CaptionAnimationStyle.values,
        json['animationStyle'],
        CaptionAnimationStyle.karaoke,
      ),
      isAllCaps: json['isAllCaps'] as bool? ?? false,
      maxLines: json['maxLines'] as int? ?? 2,
      predefinedTemplate: _enumFromIndex(
        CaptionTemplate.values,
        json['predefinedTemplate'],
        CaptionTemplate.defaultTemplate,
      ),
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      shadowOffsetX: (json['shadowOffsetX'] as num?)?.toDouble() ?? 0.0,
      shadowOffsetY: (json['shadowOffsetY'] as num?)?.toDouble() ?? 0.0,
      gradientColors:
          (json['gradientColors'] as List?)
              ?.whereType<int>()
              .map(Color.new)
              .toList(),
      borderColor:
          json['borderColor'] == null
              ? null
              : Color(json['borderColor'] as int),
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 0.0,
      wordHighlightMode: _enumFromIndex(
        CaptionWordHighlight.values,
        json['wordHighlightMode'],
        CaptionWordHighlight.color,
      ),
      activeWordScale: (json['activeWordScale'] as num?)?.toDouble() ?? 1.05,
      highlightTextColor:
          json['highlightTextColor'] == null
              ? null
              : Color(json['highlightTextColor'] as int),
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'fontWeight': fontWeight.index,
      'textColor': textColor.toARGB32(),
      'highlightColor': highlightColor.toARGB32(),
      'backgroundColor': backgroundColor.toARGB32(),
      'backgroundOpacity': backgroundOpacity,
      'backgroundBorderRadius': backgroundBorderRadius,
      'shadowColor': shadowColor.toARGB32(),
      'shadowBlur': shadowBlur,
      'strokeColor': strokeColor.toARGB32(),
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
      'letterSpacing': letterSpacing,
      'shadowOffsetX': shadowOffsetX,
      'shadowOffsetY': shadowOffsetY,
      'gradientColors':
          gradientColors?.map((c) => c.toARGB32()).toList(),
      'borderColor': borderColor?.toARGB32(),
      'borderWidth': borderWidth,
      'wordHighlightMode': wordHighlightMode.index,
      'activeWordScale': activeWordScale,
      'highlightTextColor': highlightTextColor?.toARGB32(),
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
    double? letterSpacing,
    double? shadowOffsetX,
    double? shadowOffsetY,
    List<Color>? gradientColors,
    Color? borderColor,
    double? borderWidth,
    CaptionWordHighlight? wordHighlightMode,
    double? activeWordScale,
    Color? highlightTextColor,
    // Nullable fields can't be cleared via `??`, so they get explicit flags.
    bool clearGradient = false,
    bool clearBorder = false,
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
      letterSpacing: letterSpacing ?? this.letterSpacing,
      shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
      shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
      gradientColors:
          clearGradient ? null : (gradientColors ?? this.gradientColors),
      borderColor: clearBorder ? null : (borderColor ?? this.borderColor),
      borderWidth: clearBorder ? 0.0 : (borderWidth ?? this.borderWidth),
      wordHighlightMode: wordHighlightMode ?? this.wordHighlightMode,
      activeWordScale: activeWordScale ?? this.activeWordScale,
      highlightTextColor: highlightTextColor ?? this.highlightTextColor,
    );
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
    letterSpacing,
    shadowOffsetX,
    shadowOffsetY,
    gradientColors,
    borderColor,
    borderWidth,
    wordHighlightMode,
    activeWordScale,
    highlightTextColor,
  ];
}
