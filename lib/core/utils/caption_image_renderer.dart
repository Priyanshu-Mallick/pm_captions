import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/models/caption_model.dart';
import '../../data/models/caption_style_model.dart';

/// Result of rendering a caption to an image.
class CaptionImageResult {
  final String imagePath;
  final int x;
  final int y;
  final Duration startTime;
  final Duration endTime;

  const CaptionImageResult({
    required this.imagePath,
    required this.x,
    required this.y,
    required this.startTime,
    required this.endTime,
  });
}

/// Renders captions as transparent PNG images using Flutter's own text
/// rendering engine (TextPainter + Canvas).
///
/// This produces pixel-perfect output because it uses the exact same
/// Skia-based renderer that the preview widgets use.
class CaptionImageRenderer {
  CaptionImageRenderer._();

  /// Renders all captions as overlay images for the given video dimensions.
  ///
  /// For karaoke-style captions with word-level timing, renders separate
  /// images for each word-state transition so the highlight moves.
  static Future<List<CaptionImageResult>> renderAll({
    required List<CaptionModel> captions,
    required CaptionStyleModel style,
    required int videoWidth,
    required int videoHeight,
  }) async {
    // Ensure Google Fonts are loaded before rendering
    try {
      GoogleFonts.getFont(style.fontFamily);
      await GoogleFonts.pendingFonts();
    } catch (_) {}

    final tempDir = await getTemporaryDirectory();
    final outputDir = Directory(p.join(tempDir.path, 'caption_images'));
    if (await outputDir.exists()) {
      await outputDir.delete(recursive: true);
    }
    await outputDir.create(recursive: true);

    final results = <CaptionImageResult>[];

    for (var i = 0; i < captions.length; i++) {
      final caption = captions[i];

      if (style.animationStyle == CaptionAnimationStyle.karaoke &&
          caption.words.isNotEmpty) {
        // Karaoke: render one image per word-state transition
        final karaokeResults = await _renderKaraokeCaption(
          caption: caption,
          style: style,
          videoWidth: videoWidth,
          videoHeight: videoHeight,
          outputDir: outputDir.path,
          captionIndex: i,
        );
        results.addAll(karaokeResults);
      } else {
        // Static / other animations: render a single image
        final result = await _renderStaticCaption(
          text: style.isAllCaps ? caption.text.toUpperCase() : caption.text,
          style: style,
          videoWidth: videoWidth,
          videoHeight: videoHeight,
          outputPath: p.join(outputDir.path, 'cap_$i.png'),
          startTime: caption.startTime,
          endTime: caption.endTime,
        );
        if (result != null) results.add(result);
      }
    }

    return results;
  }

  /// Renders a static (non-animated) caption to a PNG.
  static Future<CaptionImageResult?> _renderStaticCaption({
    required String text,
    required CaptionStyleModel style,
    required int videoWidth,
    required int videoHeight,
    required String outputPath,
    required Duration startTime,
    required Duration endTime,
  }) async {
    if (text.trim().isEmpty) return null;

    final scaleFactor = videoHeight / 480.0;

    // Build the exact same TextStyle as the preview
    final shadows = _buildShadows(style, scaleFactor);
    final textStyle = GoogleFonts.getFont(
      style.fontFamily,
      fontSize: style.fontSize * scaleFactor,
      fontWeight: style.fontWeight,
      color: style.textColor,
      shadows: shadows,
      height: style.lineSpacing,
    );

    // Outer padding (same 16 logical pixels as VideoPreviewWidget)
    final outerPadding = 16.0 * scaleFactor;
    // Inner padding (same as _CaptionBox)
    final hPadding = style.horizontalPadding * scaleFactor;
    final vPadding = style.horizontalPadding * 0.4 * scaleFactor;

    // Max text width: video width minus outer padding on both sides,
    // minus inner box padding on both sides
    final maxTextWidth = videoWidth - (2 * outerPadding) - (2 * hPadding);

    // Layout text using TextPainter (same engine as Text widget)
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textAlign: style.textAlign,
      maxLines: style.maxLines,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: maxTextWidth);

    final textWidth = textPainter.width;
    final textHeight = textPainter.height;

    // Image dimensions = text + inner padding
    final imgWidth = (textWidth + 2 * hPadding).ceilToDouble();
    final imgHeight = (textHeight + 2 * vPadding).ceilToDouble();

    if (imgWidth <= 0 || imgHeight <= 0) return null;

    // Paint to canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, imgWidth, imgHeight),
    );

    // Draw background box with border radius (same as _CaptionBox)
    final bgColor = style.backgroundColor.withValues(
      alpha: style.backgroundOpacity,
    );
    final bgRadius = style.backgroundBorderRadius * scaleFactor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, imgWidth, imgHeight),
        Radius.circular(bgRadius),
      ),
      Paint()..color = bgColor,
    );

    // Draw text at inner padding offset
    textPainter.paint(canvas, Offset(hPadding, vPadding));

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(imgWidth.ceil(), imgHeight.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    await File(outputPath).writeAsBytes(byteData.buffer.asUint8List());
    image.dispose();

    // Calculate position on the video frame
    final (x, y) = _calculatePosition(
      style: style,
      videoWidth: videoWidth,
      videoHeight: videoHeight,
      imgWidth: imgWidth,
      imgHeight: imgHeight,
      outerPadding: outerPadding,
    );

    return CaptionImageResult(
      imagePath: outputPath,
      x: x,
      y: y,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Renders a karaoke caption as multiple images (one per word state).
  static Future<List<CaptionImageResult>> _renderKaraokeCaption({
    required CaptionModel caption,
    required CaptionStyleModel style,
    required int videoWidth,
    required int videoHeight,
    required String outputDir,
    required int captionIndex,
  }) async {
    final results = <CaptionImageResult>[];
    final words = caption.words;
    if (words.isEmpty) return results;

    final scaleFactor = videoHeight / 480.0;
    final outerPadding = 16.0 * scaleFactor;
    final hPadding = style.horizontalPadding * scaleFactor;
    final vPadding = style.horizontalPadding * 0.4 * scaleFactor;
    final maxTextWidth = videoWidth - (2 * outerPadding) - (2 * hPadding);

    // Render one image per word transition:
    // State 0: all future (before first word)
    // State i: word i is active, words <i are past
    for (var activeIdx = -1; activeIdx < words.length; activeIdx++) {
      // Build RichText spans with karaoke coloring
      final spans = <TextSpan>[];
      for (var w = 0; w < words.length; w++) {
        final word = words[w];
        final rawWord = style.isAllCaps ? word.word.toUpperCase() : word.word;
        final wordText = w < words.length - 1 ? '$rawWord ' : rawWord;

        final bool isActive = w == activeIdx;
        final bool isPast = activeIdx >= 0 && w < activeIdx;

        Color wordColor;
        if (isActive) {
          wordColor = style.highlightColor;
        } else if (isPast) {
          wordColor = style.textColor.withValues(alpha: 0.7);
        } else {
          wordColor = style.textColor;
        }

        final shadows = _buildShadows(style, scaleFactor);
        final wordStyle = GoogleFonts.getFont(
          style.fontFamily,
          fontSize: (isActive ? style.fontSize * 1.05 : style.fontSize) *
              scaleFactor,
          fontWeight: style.fontWeight,
          color: wordColor,
          shadows: shadows,
          height: style.lineSpacing,
        );

        spans.add(TextSpan(text: wordText, style: wordStyle));
      }

      // Layout
      final textPainter = TextPainter(
        text: TextSpan(children: spans),
        textAlign: style.textAlign,
        maxLines: style.maxLines,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: maxTextWidth);

      final imgWidth = (textPainter.width + 2 * hPadding).ceilToDouble();
      final imgHeight = (textPainter.height + 2 * vPadding).ceilToDouble();

      if (imgWidth <= 0 || imgHeight <= 0) continue;

      // Paint
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, imgWidth, imgHeight),
      );

      final bgColor = style.backgroundColor.withValues(
        alpha: style.backgroundOpacity,
      );
      final bgRadius = style.backgroundBorderRadius * scaleFactor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, imgWidth, imgHeight),
          Radius.circular(bgRadius),
        ),
        Paint()..color = bgColor,
      );

      textPainter.paint(canvas, Offset(hPadding, vPadding));

      final picture = recorder.endRecording();
      final image = await picture.toImage(imgWidth.ceil(), imgHeight.ceil());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        image.dispose();
        continue;
      }

      final imgPath = p.join(
        outputDir,
        'cap_${captionIndex}_w$activeIdx.png',
      );
      await File(imgPath).writeAsBytes(byteData.buffer.asUint8List());
      image.dispose();

      final (x, y) = _calculatePosition(
        style: style,
        videoWidth: videoWidth,
        videoHeight: videoHeight,
        imgWidth: imgWidth,
        imgHeight: imgHeight,
        outerPadding: outerPadding,
      );

      // Time window for this state
      final Duration stateStart;
      final Duration stateEnd;

      if (activeIdx == -1) {
        // Before first word is active
        stateStart = caption.startTime;
        stateEnd = Duration(
          milliseconds: (words[0].start * 1000).round(),
        );
      } else if (activeIdx < words.length - 1) {
        stateStart = Duration(
          milliseconds: (words[activeIdx].start * 1000).round(),
        );
        stateEnd = Duration(
          milliseconds: (words[activeIdx + 1].start * 1000).round(),
        );
      } else {
        // Last word active until caption ends
        stateStart = Duration(
          milliseconds: (words[activeIdx].start * 1000).round(),
        );
        stateEnd = caption.endTime;
      }

      // Skip zero-duration states
      if (stateEnd <= stateStart) continue;

      results.add(CaptionImageResult(
        imagePath: imgPath,
        x: x,
        y: y,
        startTime: stateStart,
        endTime: stateEnd,
      ));
    }

    return results;
  }

  /// Builds the same shadow list as AnimatedCaption._baseTextStyle.
  static List<Shadow> _buildShadows(CaptionStyleModel style, double scale) {
    final shadows = <Shadow>[];
    if (style.shadowBlur > 0) {
      shadows.add(Shadow(
        color: style.shadowColor,
        blurRadius: style.shadowBlur * scale,
      ));
    }
    if (style.strokeWidth > 0) {
      final sw = style.strokeWidth * scale;
      for (var i = 0; i < 4; i++) {
        final dx = i < 2 ? -sw : sw;
        final dy = i.isEven ? -sw : sw;
        shadows.add(Shadow(
          color: style.strokeColor,
          offset: Offset(dx, dy),
          blurRadius: 0,
        ));
      }
    }
    return shadows;
  }

  /// Calculates the (x, y) position for the caption image on the video frame.
  ///
  /// Matches Flutter's Align(Alignment(0, verticalPosition * 2 - 1)) behavior.
  static (int, int) _calculatePosition({
    required CaptionStyleModel style,
    required int videoWidth,
    required int videoHeight,
    required double imgWidth,
    required double imgHeight,
    required double outerPadding,
  }) {
    // X: horizontal alignment
    final x = switch (style.textAlign) {
      TextAlign.left => outerPadding.round(),
      TextAlign.right => (videoWidth - imgWidth - outerPadding).round(),
      _ => ((videoWidth - imgWidth) / 2).round(),
    };

    // Y: Flutter's Align places child top at (containerH - childH) * fraction
    final y = ((videoHeight - imgHeight) * style.verticalPosition).round();

    return (x, y);
  }
}
