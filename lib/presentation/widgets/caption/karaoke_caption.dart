import 'package:flutter/material.dart';

import '../../../core/extensions/caption_style_extension.dart';
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
      padding: style.padding(),
      decoration: style.toBoxDecoration(),
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
                  children: _buildSpans(constraints.maxWidth),
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
      padding: style.padding(),
      decoration: style.toBoxDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Text(
                text,
                textAlign: style.textAlign,
                style: _buildTextStyle(
                  style.textColor,
                  false,
                  constraints.maxWidth,
                ),
                maxLines: style.maxLines,
                overflow: TextOverflow.visible,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds one span per word, plus a separate unstyled span for each gap.
  ///
  /// The gap is split out so that in box-highlight mode the block hugs the
  /// word instead of bleeding across the space after it.
  List<TextSpan> _buildSpans(double width) {
    final spans = <TextSpan>[];

    for (var i = 0; i < caption.words.length; i++) {
      final word = caption.words[i];
      final wordStart = Duration(milliseconds: (word.start * 1000).round());
      final wordEnd = Duration(milliseconds: (word.end * 1000).round());

      final isActive =
          currentPosition >= wordStart && currentPosition <= wordEnd;
      final isPast = currentPosition > wordEnd;

      final Color wordColor;
      if (isActive) {
        wordColor = style.activeWordColor;
      } else if (isPast) {
        wordColor = style.textColor.withValues(alpha: 0.7);
      } else {
        wordColor = style.textColor;
      }

      final rawWord = style.isAllCaps ? word.word.toUpperCase() : word.word;

      spans.add(
        TextSpan(
          text: rawWord,
          style: _buildTextStyle(wordColor, isActive, width),
        ),
      );

      if (i < caption.words.length - 1) {
        spans.add(
          TextSpan(
            text: ' ',
            style: _buildTextStyle(style.textColor, false, width),
          ),
        );
      }
    }

    return spans;
  }

  TextStyle _buildTextStyle(Color color, bool isHighlighted, double width) {
    return style.toTextStyle(
      color: color,
      isHighlighted: isHighlighted,
      gradientBounds: style.gradientBounds(width),
    );
  }
}
