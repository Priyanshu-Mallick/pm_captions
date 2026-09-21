import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_captions/core/constants/caption_templates.dart';
import 'package:pm_captions/core/extensions/caption_style_extension.dart';
import 'package:pm_captions/data/models/caption_style_model.dart';

void main() {
  group('CaptionTemplate persistence contract', () {
    // Templates are persisted by index (see CaptionStyleModel.toJson), so
    // reordering or inserting a value silently changes the style of every
    // already-saved project. These pins make that a failing test, not a
    // support ticket.
    test('free template indices are frozen', () {
      expect(CaptionTemplate.defaultTemplate.index, 0);
      expect(CaptionTemplate.tiktok.index, 1);
      expect(CaptionTemplate.youtube.index, 2);
      expect(CaptionTemplate.instagram.index, 3);
      expect(CaptionTemplate.minimal.index, 4);
      expect(CaptionTemplate.bold.index, 5);
      expect(CaptionTemplate.neon.index, 6);
      expect(CaptionTemplate.typewriter.index, 7);
    });

    test('Pro templates are appended after the free ones', () {
      expect(CaptionTemplate.karaokeBox.index, 8);
      expect(CaptionTemplate.hormozi.index, 9);
      expect(CaptionTemplate.cyberpunk.index, 10);
      expect(CaptionTemplate.wordPop.index, 11);
      expect(CaptionTemplate.comicImpact.index, 12);
      expect(CaptionTemplate.frostedGlass.index, 13);
    });

    test('isPro is true for exactly the six Pro templates', () {
      final pro = CaptionTemplate.values.where((t) => t.isPro).toList();
      expect(pro, [
        CaptionTemplate.karaokeBox,
        CaptionTemplate.hormozi,
        CaptionTemplate.cyberpunk,
        CaptionTemplate.wordPop,
        CaptionTemplate.comicImpact,
        CaptionTemplate.frostedGlass,
      ]);
    });

    test('every template has a preset that reports itself', () {
      for (final t in CaptionTemplate.values) {
        expect(
          CaptionTemplates.fromTemplate(t).predefinedTemplate,
          t,
          reason: 'fromTemplate(${t.name}) returned the wrong preset',
        );
      }
    });
  });

  group('CaptionStyleModel serialization', () {
    test('round-trips the new Pro style fields', () {
      const original = CaptionStyleModel(
        predefinedTemplate: CaptionTemplate.cyberpunk,
        letterSpacing: 1.5,
        shadowOffsetX: 4.0,
        shadowOffsetY: -2.0,
        gradientColors: [Color(0xFFFF2BD1), Color(0xFF00F0FF)],
        borderColor: Color(0x66FFFFFF),
        borderWidth: 1.0,
      );

      final restored = CaptionStyleModel.fromJsonString(
        original.toJsonString(),
      );

      expect(restored, original);
      expect(restored.gradientColors, original.gradientColors);
      expect(restored.hasGradient, isTrue);
      expect(restored.hasBorder, isTrue);
    });

    test('legacy JSON without the new keys falls back to defaults', () {
      // A style saved before Pro styles existed.
      final restored = CaptionStyleModel.fromJson({
        'fontFamily': 'Montserrat',
        'fontSize': 22.0,
        'predefinedTemplate': CaptionTemplate.tiktok.index,
      });

      expect(restored.predefinedTemplate, CaptionTemplate.tiktok);
      expect(restored.letterSpacing, 0.0);
      expect(restored.shadowOffsetX, 0.0);
      expect(restored.shadowOffsetY, 0.0);
      expect(restored.gradientColors, isNull);
      expect(restored.borderColor, isNull);
      expect(restored.borderWidth, 0.0);
      expect(restored.hasGradient, isFalse);
      expect(restored.hasBorder, isFalse);
    });

    test('an out-of-range template index degrades instead of throwing', () {
      // Happens if the user downgrades after saving a newer template.
      final restored = CaptionStyleModel.fromJson({
        'predefinedTemplate': 999,
        'animationStyle': -1,
      });

      expect(restored.predefinedTemplate, CaptionTemplate.defaultTemplate);
      expect(restored.animationStyle, CaptionAnimationStyle.karaoke);
    });

    test('copyWith can clear the gradient and border', () {
      const styled = CaptionStyleModel(
        gradientColors: [Colors.red, Colors.blue],
        borderColor: Colors.white,
        borderWidth: 2.0,
      );

      final plain = styled.copyWith(clearGradient: true, clearBorder: true);

      expect(plain.gradientColors, isNull);
      expect(plain.borderColor, isNull);
      expect(plain.borderWidth, 0.0);
    });
  });

  group('Pro presets', () {
    test('all use karaoke, the only animation export reproduces', () {
      for (final t in CaptionTemplate.values.where((t) => t.isPro)) {
        expect(
          CaptionTemplates.fromTemplate(t).animationStyle,
          CaptionAnimationStyle.karaoke,
          reason: '${t.name} would animate in preview but export static',
        );
      }
    });

    // The reason to pay cannot be "same style, different font and colour" —
    // the free editor already exposes font, colour and size pickers, so a
    // palette swap is not a feature. Every Pro preset must therefore differ
    // from every free preset in at least one render *mechanic*.
    //
    // This is the guard for a real regression: the first cut of the Pro tier
    // shipped a style that was the TikTok preset with a different font, and
    // this assertion is what would have caught it.
    test('each Pro style differs from every free style by a mechanic', () {
      // Fields the free presets have no way to vary.
      String mechanics(CaptionStyleModel s) => [
        s.wordHighlightMode.name,
        s.activeWordScale,
        s.gradientColors?.length ?? 0,
        s.borderColor != null && s.borderWidth > 0,
        s.shadowOffsetX,
        s.shadowOffsetY,
        s.letterSpacing,
      ].join('|');

      final freeMechanics =
          CaptionTemplate.values
              .where((t) => !t.isPro)
              .map((t) => mechanics(CaptionTemplates.fromTemplate(t)))
              .toSet();

      for (final t in CaptionTemplate.values.where((t) => t.isPro)) {
        final style = CaptionTemplates.fromTemplate(t);
        expect(
          freeMechanics,
          isNot(contains(mechanics(style))),
          reason:
              'Pro style "${t.name}" is mechanically identical to a free '
              'style — it differs only by font/colour, which users can '
              'already change for free.',
        );
      }
    });

    test('box-mode styles give the active word a contrasting colour', () {
      for (final t in CaptionTemplate.values) {
        final style = CaptionTemplates.fromTemplate(t);
        if (style.wordHighlightMode != CaptionWordHighlight.box) continue;

        // In box mode highlightColor paints the block, so reusing it for the
        // glyphs would render the word invisible against its own block.
        expect(
          style.activeWordColor,
          isNot(style.highlightColor),
          reason: '${t.name} would draw its active word invisibly',
        );
      }
    });

    test('colour-mode active word still uses the accent colour', () {
      const s = CaptionStyleModel(highlightColor: Color(0xFFFFD700));
      expect(s.wordHighlightMode, CaptionWordHighlight.color);
      expect(s.activeWordColor, const Color(0xFFFFD700));
    });

    test('highlight mode and scale round-trip', () {
      const original = CaptionStyleModel(
        wordHighlightMode: CaptionWordHighlight.box,
        activeWordScale: 1.4,
        highlightTextColor: Color(0xFF07160D),
      );

      final restored = CaptionStyleModel.fromJsonString(
        original.toJsonString(),
      );

      expect(restored, original);
      expect(restored.wordHighlightMode, CaptionWordHighlight.box);
      expect(restored.activeWordScale, 1.4);
    });

    test('legacy styles default to colour mode and the stock bump', () {
      final restored = CaptionStyleModel.fromJson({'fontSize': 22.0});
      expect(restored.wordHighlightMode, CaptionWordHighlight.color);
      expect(restored.activeWordScale, 1.05);
      expect(restored.highlightTextColor, isNull);
    });
  });
}
