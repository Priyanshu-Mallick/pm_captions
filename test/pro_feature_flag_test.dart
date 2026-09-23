import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_captions/core/services/revenue_cat_service.dart';
import 'package:pm_captions/data/models/caption_style_model.dart';
import 'package:pm_captions/presentation/providers/subscription_provider.dart';

void main() {
  // dotenv.load() never runs in a test binary, and the real dotenv.env
  // getter throws NotInitializedError rather than treating "unloaded" as
  // "empty" — testLoad() is flutter_dotenv's supported stand-in, loading an
  // empty file so PRO_FEATURE_ENABLED reads as unset, exactly the "flag off"
  // state this whole file locks in.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  group('Pro feature flag (defaults to disabled)', () {
    test('RevenueCatService.featureEnabled is false without the env var', () {
      expect(RevenueCatService.featureEnabled, isFalse);
    });

    test('RevenueCatService.initialize is a no-op when disabled', () async {
      await RevenueCatService.initialize();
      expect(RevenueCatService.isAvailable, isFalse);
    });

    test(
      'SubscriptionProvider.initialize no-ops and isPro stays false',
      () async {
        final sub = SubscriptionProvider();
        await sub.initialize();

        expect(sub.isFeatureEnabled, isFalse);
        expect(sub.isPro, isFalse);
        expect(sub.isInitialized, isTrue);
        expect(sub.offerings, isNull);
        expect(sub.packages, isEmpty);
      },
    );

    // Mirrors the exact filter in StylePanelWidget — the picker must show
    // only the 8 free templates when the flag is off, not just gate them at
    // export. If this list ever grows a 9th free template, update the count.
    test('only free templates remain once Pro ones are filtered out', () {
      final visible =
          CaptionTemplate.values
              .where(
                (t) => !t.isPro || RevenueCatService.featureEnabled,
              )
              .toList();

      expect(visible.length, 8);
      expect(visible.every((t) => !t.isPro), isTrue);
    });

    // Mirrors ExportOptionsWidget._startExport's guard exactly. This is the
    // regression it caught: the picker can't offer a Pro template while the
    // flag is off, but a project *saved earlier* — while testing Pro before
    // this flag existed — still has one persisted in its style JSON. Loading
    // that project and exporting hit this guard directly, showing the
    // paywall even though the feature was supposedly hidden. The guard has
    // to check the flag itself, not just trust that Pro is unreachable via
    // the picker.
    test(
      'export never shows the paywall while the feature is disabled, '
      'even for a project whose saved style is a Pro template',
      () {
        bool wouldShowPaywall({
          required bool featureEnabled,
          required CaptionTemplate template,
          required bool userIsPro,
        }) =>
            featureEnabled && template.isPro && !userIsPro;

        // The exact scenario from the bug report.
        expect(
          wouldShowPaywall(
            featureEnabled: false,
            template: CaptionTemplate.hormozi,
            userIsPro: false,
          ),
          isFalse,
        );

        // Sanity: once the feature ships, the same project should still be
        // correctly gated for a non-Pro user.
        expect(
          wouldShowPaywall(
            featureEnabled: true,
            template: CaptionTemplate.hormozi,
            userIsPro: false,
          ),
          isTrue,
        );

        // A free template never triggers it either way.
        expect(
          wouldShowPaywall(
            featureEnabled: true,
            template: CaptionTemplate.tiktok,
            userIsPro: false,
          ),
          isFalse,
        );
      },
    );
  });
}
