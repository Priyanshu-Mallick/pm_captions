import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:pm_captions/core/constants/caption_templates.dart';
import 'package:pm_captions/data/models/caption_style_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Poppins font loads from bundled assets when runtime fetching is disabled', (
    WidgetTester tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('Regular', style: GoogleFonts.poppins(fontWeight: FontWeight.w400)),
              Text('Medium', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              Text('SemiBold', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Text('Bold', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              Text('ExtraBold', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
              Text('Black', style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
              Text('Light', style: GoogleFonts.poppins(fontWeight: FontWeight.w300)),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Regular'), findsOneWidget);
    expect(find.text('Bold'), findsOneWidget);
  });

  // NOTE ON APPROACH: the obvious way to test this — actually await
  // GoogleFonts.pendingFonts() after requesting every template's font — was
  // tried and HANGS under `flutter test`. The test binary runs with
  // --disable-asset-fonts and a synthetic test-font substitute, so the real
  // FontLoader future this depends on never resolves. That's a test-harness
  // limitation, not a signal about whether the bundled fonts are correct, so
  // this test instead statically replicates google_fonts' own matching rule
  // and checks it against the files on disk — fast, and it does not depend
  // on the test environment's font pipeline.
  //
  // google_fonts's real algorithm (verified against google_fonts 6.3.0
  // source, lib/src/google_fonts_base.dart):
  //   1. If the exact requested weight isn't registered for that family,
  //      pick the closest available weight by |weight.index - target.index|
  //      (_closestMatch / _computeMatch). This is why boldStyle can request
  //      Oswald w900 and still correctly resolve to "Oswald-Bold" — Oswald
  //      only goes up to w700 in google_fonts' own data.
  //   2. Look for a bundled asset whose filename (without extension) *ends
  //      with* "<family>-<weightPart>" — keeping any space in a multi-word
  //      family name (e.g. "Bebas Neue-Regular", not "BebasNeue-Regular").
  //      An earlier version of this test stripped spaces, which is why it
  //      passed while a real device crashed exporting the Hormozi style: it
  //      was checking a different rule than the one google_fonts uses.
  //
  // The available-weight lists below were read directly from each family's
  // generated function in google_fonts' lib/src/google_fonts_parts/*.dart
  // (grep for "fontWeight: FontWeight.w" inside e.g. `static TextStyle
  // oswald(...)`). Re-verify them if google_fonts is upgraded.
  const availableWeights = {
    'Montserrat': [100, 200, 300, 400, 500, 600, 700, 800, 900],
    'Roboto': [100, 300, 400, 500, 700, 900],
    'Raleway': [100, 200, 300, 400, 500, 600, 700, 800, 900],
    'Bebas Neue': [400],
    'Anton': [400],
    'Bangers': [400],
    'Courier Prime': [400, 700],
    'Poppins': [100, 200, 300, 400, 500, 600, 700, 800, 900],
    'Oswald': [200, 300, 400, 500, 600, 700],
  };

  const weightToFilenamePart = {
    100: 'Thin',
    200: 'ExtraLight',
    300: 'Light',
    400: 'Regular',
    500: 'Medium',
    600: 'SemiBold',
    700: 'Bold',
    800: 'ExtraBold',
    900: 'Black',
  };

  /// google_fonts' `_computeMatch`: absolute distance between weight indices
  /// (each step of 100 is one index step), no style mismatch here since we
  /// only ever request FontStyle.normal.
  int closestAvailableWeight(String family, int requestedWeight) {
    final available = availableWeights[family];
    expect(
      available,
      isNotNull,
      reason:
          'Unknown font family "$family" — add its available weights to '
          'availableWeights above (see lib/src/google_fonts_parts/*.dart).',
    );
    return available!.reduce(
      (a, b) =>
          (a - requestedWeight).abs() <= (b - requestedWeight).abs() ? a : b,
    );
  }

  test('every template resolves to a font+weight bundled in google_fonts/', () {
    final bundled =
        Directory('google_fonts').listSync().whereType<File>().map((f) => p.basename(f.path)).toList();

    bool hasAsset(String family, String weightPart) {
      final suffix = '$family-$weightPart';
      return bundled.any((name) {
        for (final ext in ['.ttf', '.otf']) {
          if (name.endsWith(ext)) {
            return name.substring(0, name.length - ext.length).endsWith(suffix);
          }
        }
        return false;
      });
    }

    for (final template in CaptionTemplate.values) {
      final style = CaptionTemplates.fromTemplate(template);
      final family = style.fontFamily;
      final requestedWeight = style.fontWeight.value;
      final resolvedWeight = closestAvailableWeight(family, requestedWeight);
      final weightPart = weightToFilenamePart[resolvedWeight]!;

      expect(
        hasAsset(family, weightPart),
        isTrue,
        reason:
            'Template "${template.name}" requests "$family" at w$requestedWeight, '
            'which google_fonts resolves to its closest available weight '
            'w$resolvedWeight ("$weightPart") — but no bundled file ends in '
            '"$family-$weightPart.ttf/.otf". Export would silently fall back '
            'to the platform default typeface for this style. '
            'Bundled: $bundled',
      );
    }
  });
}
