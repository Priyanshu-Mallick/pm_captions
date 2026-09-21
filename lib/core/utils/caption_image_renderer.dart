import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/models/caption_model.dart';
import '../../data/models/caption_style_model.dart';
import '../extensions/caption_style_extension.dart';

/// Result of rendering a caption to an overlay image.
///
/// Images are written as headerless raw RGBA, not PNG — the bundled FFmpeg
/// build (ffmpeg-kit min-gpl) ships without a PNG decoder, so every overlay
/// failed with "Decoder (codec png) not found" and the whole export died.
/// Raw RGBA needs no decoder, which is why [width] and [height] are carried
/// here: the rawvideo demuxer cannot infer them from the file.
class CaptionImageResult {
  final String imagePath;
  final int width;
  final int height;
  final int x;
  final int y;
  final Duration startTime;
  final Duration endTime;

  const CaptionImageResult({
    required this.imagePath,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    required this.startTime,
    required this.endTime,
  });
}

/// Renders captions as transparent raw-RGBA overlay images using Flutter's
/// own text rendering engine (TextPainter + Canvas).
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
          outputPath: p.join(outputDir.path, 'cap_$i.rgba'),
          startTime: caption.startTime,
          endTime: caption.endTime,
        );
        if (result != null) results.add(result);
      }
    }

    return results;
  }

  /// Renders a static (non-animated) caption to a raw RGBA buffer.
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

    // Outer padding (same 16 logical pixels as VideoPreviewWidget)
    final outerPadding = 16.0 * scaleFactor;
    // Inner padding (same as _CaptionBox)
    final hPadding = style.horizontalPadding * scaleFactor;
    final vPadding = style.horizontalPadding * 0.4 * scaleFactor;

    // Max text width: video width minus outer padding on both sides,
    // minus inner box padding on both sides
    final maxTextWidth = videoWidth - (2 * outerPadding) - (2 * hPadding);

    // Build the exact same TextStyle as the preview
    final textStyle = style.toTextStyle(
      scale: scaleFactor,
      gradientBounds: style.gradientBounds(maxTextWidth, scale: scaleFactor),
    );

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
    style.paintBackground(
      canvas,
      Rect.fromLTWH(0, 0, imgWidth, imgHeight),
      scale: scaleFactor,
    );

    // Draw text at inner padding offset
    textPainter.paint(canvas, Offset(hPadding, vPadding));

    // Convert to image
    final picture = recorder.endRecording();
    final pixelWidth = imgWidth.ceil();
    final pixelHeight = imgHeight.ceil();
    final image = await picture.toImage(pixelWidth, pixelHeight);
    // Straight (non-premultiplied) alpha: FFmpeg's `rgba` pix_fmt expects it,
    // and premultiplied bytes would darken every antialiased glyph edge and
    // any soft shadow.
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (byteData == null) {
      image.dispose();
      return null;
    }

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
      width: pixelWidth,
      height: pixelHeight,
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
      // Build spans with karaoke coloring. Mirrors KaraokeCaption._buildSpans:
      // the inter-word space is its own span so that a box highlight hugs the
      // word rather than bleeding across the gap after it.
      final spans = <TextSpan>[];
      for (var w = 0; w < words.length; w++) {
        final word = words[w];
        final rawWord = style.isAllCaps ? word.word.toUpperCase() : word.word;

        final bool isActive = w == activeIdx;
        final bool isPast = activeIdx >= 0 && w < activeIdx;

        Color wordColor;
        if (isActive) {
          wordColor = style.activeWordColor;
        } else if (isPast) {
          wordColor = style.textColor.withValues(alpha: 0.7);
        } else {
          wordColor = style.textColor;
        }

        final gradientBounds = style.gradientBounds(
          maxTextWidth,
          scale: scaleFactor,
        );

        spans.add(
          TextSpan(
            text: rawWord,
            style: style.toTextStyle(
              color: wordColor,
              scale: scaleFactor,
              isHighlighted: isActive,
              gradientBounds: gradientBounds,
            ),
          ),
        );

        if (w < words.length - 1) {
          spans.add(
            TextSpan(
              text: ' ',
              style: style.toTextStyle(
                color: style.textColor,
                scale: scaleFactor,
                gradientBounds: gradientBounds,
              ),
            ),
          );
        }
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

      style.paintBackground(
        canvas,
        Rect.fromLTWH(0, 0, imgWidth, imgHeight),
        scale: scaleFactor,
      );

      textPainter.paint(canvas, Offset(hPadding, vPadding));

      final picture = recorder.endRecording();
      final pixelWidth = imgWidth.ceil();
      final pixelHeight = imgHeight.ceil();
      final image = await picture.toImage(pixelWidth, pixelHeight);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (byteData == null) {
        image.dispose();
        continue;
      }

      final imgPath = p.join(
        outputDir,
        'cap_${captionIndex}_w$activeIdx.rgba',
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
        width: pixelWidth,
        height: pixelHeight,
        x: x,
        y: y,
        startTime: stateStart,
        endTime: stateEnd,
      ));
    }

    return results;
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
