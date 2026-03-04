import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/caption_model.dart';
import '../../../data/models/caption_style_model.dart';

/// Renders caption text with karaoke-style word highlighting.
///
/// Words are highlighted in sequence based on the current video position,
/// creating a karaoke sing-along effect.
class KaraokeCaption extends StatelessWidget {
  final CaptionModel caption;
  final CaptionStyleModel style;
  final Duration currentPosition;

  const KaraokeCaption({
    super.key,
    required this.caption,
    required this.style,
    required this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    final displayText =
        style.isAllCaps ? caption.text.toUpperCase() : caption.text;

    // If no word-level data, render plain text
    if (caption.words.isEmpty) {
      return _buildPlainText(displayText);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: style.horizontalPadding,
        vertical: style.horizontalPadding * 0.4,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor.withValues(alpha: style.backgroundOpacity),
        borderRadius: BorderRadius.circular(style.backgroundBorderRadius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: constraints.maxWidth,
              child: RichText(
                textAlign: style.textAlign,
                maxLines: style.maxLines,
                overflow: TextOverflow.visible,
                text: TextSpan(
                  children:
                      caption.words.map((word) {
                        final wordStart = Duration(
                          milliseconds: (word.start * 1000).round(),
                        );
                        final wordEnd = Duration(
                          milliseconds: (word.end * 1000).round(),
                        );

                        // Determine word state based on current position
                        final isActive =
                            currentPosition >= wordStart &&
                            currentPosition <= wordEnd;
                        final isPast = currentPosition > wordEnd;

                        Color wordColor;
                        if (isActive) {
                          wordColor = style.highlightColor;
                        } else if (isPast) {
                          wordColor = style.textColor.withValues(alpha: 0.7);
                        } else {
                          wordColor = style.textColor;
                        }

                        final rawWord =
                            style.isAllCaps
                                ? word.word.toUpperCase()
                                : word.word;

                        return TextSpan(
                          text: '$rawWord ',
                          style: _buildTextStyle(wordColor, isActive),
                        );
                      }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlainText(String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: style.horizontalPadding,
        vertical: style.horizontalPadding * 0.4,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor.withValues(alpha: style.backgroundOpacity),
        borderRadius: BorderRadius.circular(style.backgroundBorderRadius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Text(
                text,
                textAlign: style.textAlign,
                style: _buildTextStyle(style.textColor, false),
                maxLines: style.maxLines,
                overflow: TextOverflow.visible,
              ),
            ),
          );
        },
      ),
    );
  }

  TextStyle _buildTextStyle(Color color, bool isHighlighted) {
    final shadows = <Shadow>[];
    if (style.shadowBlur > 0) {
      shadows.add(
        Shadow(color: style.shadowColor, blurRadius: style.shadowBlur),
      );
    }
    if (style.strokeWidth > 0) {
      // Simulate stroke with multiple shadows
      for (var i = 0; i < 4; i++) {
        final dx = i < 2 ? -style.strokeWidth : style.strokeWidth;
        final dy = i.isEven ? -style.strokeWidth : style.strokeWidth;
        shadows.add(
          Shadow(
            color: style.strokeColor,
            offset: Offset(dx, dy),
            blurRadius: 0,
          ),
        );
      }
    }

    return GoogleFonts.getFont(
      style.fontFamily,
      fontSize: isHighlighted ? style.fontSize * 1.05 : style.fontSize,
      fontWeight: style.fontWeight,
      color: color,
      shadows: shadows.isNotEmpty ? shadows : null,
      height: style.lineSpacing,
    );
  }
}
