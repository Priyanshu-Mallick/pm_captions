import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/caption_model.dart';
import '../../../data/models/caption_style_model.dart';
import 'karaoke_caption.dart';

/// Animated caption widget that applies the selected animation style.
///
/// Supports: none, fadeIn, slideUp, typewriter, and karaoke animations.
class AnimatedCaption extends StatelessWidget {
  final CaptionModel? caption;
  final CaptionStyleModel style;
  final Duration currentPosition;

  const AnimatedCaption({
    super.key,
    this.caption,
    required this.style,
    required this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    if (caption == null) return const SizedBox.shrink();

    switch (style.animationStyle) {
      case CaptionAnimationStyle.karaoke:
        return KaraokeCaption(
          caption: caption!,
          style: style,
          currentPosition: currentPosition,
        );

      case CaptionAnimationStyle.fadeIn:
        return _buildFadeIn();

      case CaptionAnimationStyle.slideUp:
        return _buildSlideUp();

      case CaptionAnimationStyle.typewriter:
        return _buildTypewriter();

      case CaptionAnimationStyle.none:
        return _buildStatic();
    }
  }

  Widget _buildStatic() {
    return _buildFittedText(_displayText);
  }

  Widget _buildFadeIn() {
    return _buildFittedText(_displayText)
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }

  Widget _buildSlideUp() {
    return _buildFittedText(_displayText).animate().slideY(
      begin: 0.5,
      end: 0,
      duration: 400.ms,
      curve: Curves.easeOut,
    );
  }

  Widget _buildTypewriter() {
    if (caption == null) return const SizedBox.shrink();

    // Calculate how many characters to show based on elapsed time
    final elapsed = currentPosition - caption!.startTime;
    final captionDuration = caption!.endTime - caption!.startTime;
    final totalChars = _displayText.length;

    double progress = 0.0;
    if (captionDuration.inMilliseconds > 0) {
      progress = elapsed.inMilliseconds / captionDuration.inMilliseconds;
    }
    progress = progress.clamp(0.0, 1.0);

    final visibleChars = (totalChars * progress).round();
    final visibleText = _displayText.substring(0, visibleChars);

    return _buildFittedText(visibleText);
  }

  Widget _buildFittedText(String text) {
    return _CaptionBox(
      style: style,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Text(
                text,
                textAlign: style.textAlign,
                style: _baseTextStyle,
                maxLines: style.maxLines,
                overflow: TextOverflow.visible,
              ),
            ),
          );
        },
      ),
    );
  }

  String get _displayText {
    if (caption == null) return '';
    return style.isAllCaps ? caption!.text.toUpperCase() : caption!.text;
  }

  TextStyle get _baseTextStyle {
    final shadows = <Shadow>[];
    if (style.shadowBlur > 0) {
      shadows.add(
        Shadow(color: style.shadowColor, blurRadius: style.shadowBlur),
      );
    }
    if (style.strokeWidth > 0) {
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
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      color: style.textColor,
      shadows: shadows.isNotEmpty ? shadows : null,
      height: style.lineSpacing,
    );
  }
}

/// Container box for caption text with background styling.
class _CaptionBox extends StatelessWidget {
  final CaptionStyleModel style;
  final Widget child;

  const _CaptionBox({required this.style, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: style.horizontalPadding,
        vertical: style.horizontalPadding * 0.4,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor.withValues(alpha: style.backgroundOpacity),
        borderRadius: BorderRadius.circular(style.backgroundBorderRadius),
      ),
      child: child,
    );
  }
}
