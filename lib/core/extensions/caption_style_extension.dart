import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';

import '../../data/models/caption_style_model.dart';

final _fontFallbackLog = Logger();

/// Single source of truth for turning a [CaptionStyleModel] into pixels.
///
/// Both the live editor preview and the export renderer go through here, so a
/// style change lands in the exported video exactly as the user saw it. Any new
/// visual field must be honoured in this extension and nowhere else.
///
/// [scale] is 1.0 for the preview and `videoHeight / 480` for export, because
/// style values are authored in "480p logical" units.
extension CaptionStyleRender on CaptionStyleModel {
  /// Shadow + faux-stroke list.
  ///
  /// The stroke is simulated with four offset hard shadows rather than a real
  /// outline, so very thick strokes look slightly softer at the corners than a
  /// true outline would.
  List<Shadow> buildShadows({double scale = 1.0}) {
    final shadows = <Shadow>[];

    if (shadowBlur > 0) {
      shadows.add(
        Shadow(
          color: shadowColor,
          blurRadius: shadowBlur * scale,
          offset: Offset(shadowOffsetX * scale, shadowOffsetY * scale),
        ),
      );
    }

    if (strokeWidth > 0) {
      final sw = strokeWidth * scale;
      for (var i = 0; i < 4; i++) {
        final dx = i < 2 ? -sw : sw;
        final dy = i.isEven ? -sw : sw;
        shadows.add(
          Shadow(color: strokeColor, offset: Offset(dx, dy), blurRadius: 0),
        );
      }
    }

    return shadows;
  }

  /// Colour the active karaoke word's glyphs should take.
  ///
  /// In [CaptionWordHighlight.box] mode the accent colour becomes the block
  /// behind the word, so the glyphs need their own contrasting colour; black
  /// is the safe default because accent colours are overwhelmingly bright
  /// (yellow, lime, cyan).
  Color get activeWordColor => switch (wordHighlightMode) {
    CaptionWordHighlight.color => highlightTextColor ?? highlightColor,
    CaptionWordHighlight.box => highlightTextColor ?? Colors.black,
  };

  /// Builds the text style for a caption or a single karaoke word.
  ///
  /// [color] overrides [textColor] (karaoke uses it for active/past words).
  /// [isHighlighted] marks the active karaoke word, which applies the size pop
  /// and, in box mode, the block behind the glyphs.
  /// [gradientBounds] is the laid-out text rect; a gradient is only painted
  /// when it is supplied, since the shader needs real extents to ramp across.
  TextStyle toTextStyle({
    Color? color,
    double scale = 1.0,
    bool isHighlighted = false,
    Rect? gradientBounds,
  }) {
    final shadows = buildShadows(scale: scale);
    final effectiveColor = color ?? textColor;

    // A gradient replaces the solid fill, but never the karaoke highlight —
    // highlighting the active word is the whole point of the animation, so a
    // gradient would hide it.
    final useGradient =
        hasGradient && !isHighlighted && gradientBounds != null;

    // The block behind the active word. TextStyle.background is used rather
    // than hand-painted rects because RichText (preview) and TextPainter
    // (export) both honour it, so the two paths cannot drift.
    //
    // ponytail: the block is a square-cornered rect hugging the glyph advance.
    // Rounded, padded blocks would need a shared CustomPainter measuring each
    // word box via getBoxesForSelection — worth it only if users ask.
    final highlightBox =
        isHighlighted && wordHighlightMode == CaptionWordHighlight.box
            ? (Paint()..color = highlightColor)
            : null;

    final resolvedFontSize =
        (isHighlighted ? fontSize * activeWordScale : fontSize) * scale;
    final resolvedLetterSpacing = letterSpacing * scale;
    final resolvedShadows = shadows.isNotEmpty ? shadows : null;
    final foregroundPaint =
        useGradient
            ? (Paint()
              ..shader = LinearGradient(
                colors: gradientColors!,
              ).createShader(gradientBounds))
            : null;

    // GoogleFonts.getFont fires font loading as a detached background
    // Future (see the package's loadFontIfNecessary) rather than throwing
    // synchronously, so a missing/mismatched bundled asset for `fontFamily`
    // surfaces unpredictably later rather than right here — sometimes as a
    // caught export failure, sometimes as a bare unhandled-future error.
    // Either way the export must not die over a typography mistake in one
    // template preset, so any failure degrades to the platform's default
    // typeface instead of losing the user's export.
    try {
      return GoogleFonts.getFont(
        fontFamily,
        fontSize: resolvedFontSize,
        fontWeight: fontWeight,
        color: useGradient ? null : effectiveColor,
        foreground: foregroundPaint,
        background: highlightBox,
        letterSpacing: resolvedLetterSpacing,
        shadows: resolvedShadows,
        height: lineSpacing,
      );
    } catch (e) {
      _fontFallbackLog.w(
        'Font "$fontFamily" ($fontWeight) failed to load — falling back to '
        'the platform default typeface for this caption. $e',
      );
      return TextStyle(
        fontSize: resolvedFontSize,
        fontWeight: fontWeight,
        color: useGradient ? null : effectiveColor,
        foreground: foregroundPaint,
        background: highlightBox,
        letterSpacing: resolvedLetterSpacing,
        shadows: resolvedShadows,
        height: lineSpacing,
      );
    }
  }

  /// Gradient extents for [toTextStyle].
  ///
  /// Deliberately derived from the *available* text width rather than the
  /// laid-out glyph width: both the preview and the export renderer know the
  /// available width before laying text out, so the ramp is identical on both
  /// sides with no extra measure pass. A short centred caption therefore
  /// samples only the middle of the ramp — but it samples the same middle in
  /// the preview and in the exported video, which is what matters.
  Rect gradientBounds(double availableWidth, {double scale = 1.0}) => Rect.
      fromLTWH(
    0,
    0,
    availableWidth,
    fontSize * lineSpacing * maxLines * scale,
  );

  /// Padding around the text inside the background pill.
  EdgeInsets padding({double scale = 1.0}) => EdgeInsets.symmetric(
    horizontal: horizontalPadding * scale,
    vertical: horizontalPadding * 0.4 * scale,
  );

  /// The background pill, for the widget-based preview.
  BoxDecoration toBoxDecoration({double scale = 1.0}) => BoxDecoration(
    color: backgroundColor.withValues(alpha: backgroundOpacity),
    borderRadius: BorderRadius.circular(backgroundBorderRadius * scale),
    border:
        hasBorder
            ? Border.all(color: borderColor!, width: borderWidth * scale)
            : null,
  );

  /// The same background pill, for the canvas-based export renderer.
  ///
  /// ponytail: the fill is a flat translucent color, not a real backdrop blur —
  /// the renderer paints into a transparent PNG that FFmpeg composites, so it
  /// has no access to the video pixels behind it. A true frosted effect would
  /// need a per-overlay `crop -> boxblur -> overlay` FFmpeg chain, which roughly
  /// doubles an already-large filter graph (one chain per karaoke word state).
  void paintBackground(Canvas canvas, Rect rect, {double scale = 1.0}) {
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(backgroundBorderRadius * scale),
    );

    canvas.drawRRect(
      rrect,
      Paint()..color = backgroundColor.withValues(alpha: backgroundOpacity),
    );

    if (hasBorder) {
      final w = borderWidth * scale;
      canvas.drawRRect(
        rrect.deflate(w / 2),
        Paint()
          ..color = borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = w,
      );
    }
  }
}
