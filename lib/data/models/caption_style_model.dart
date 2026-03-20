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
