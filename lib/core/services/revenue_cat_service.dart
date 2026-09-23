import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Thin wrapper around the RevenueCat SDK.
///
/// Every method is safe to call when RevenueCat is not configured (no API key
/// in `.env`, or `configure` failed). In that state [isAvailable] is false and
/// the methods return benign defaults instead of throwing, so the app behaves
/// exactly as it did before subscriptions existed.
class RevenueCatService {
  RevenueCatService._();

  static final _log = Logger();

  static bool _available = false;
  static String _entitlementId = 'pro_access';

  /// Master switch for the whole Pro feature (styles, paywall, badges,
  /// settings card, RevenueCat itself) — read once from `.env`.
  ///
  /// This is a release-readiness flag, not a per-user entitlement kill
  /// switch: it hides Pro from everyone on this build, independent of
  /// whether a real subscription exists. Flip `PRO_FEATURE_ENABLED=true` in
  /// `.env` when the Pro tier is ready to ship.
  static final bool featureEnabled =
      dotenv.maybeGet('PRO_FEATURE_ENABLED')?.trim().toLowerCase() == 'true';

  /// Whether the SDK configured successfully and store calls can be made.
  static bool get isAvailable => _available;

  /// The entitlement that grants Pro access.
  static String get entitlementId => _entitlementId;

  /// Configures the SDK with the platform's public key. Never throws.
  ///
  /// No-ops entirely when [featureEnabled] is false, so a build with the
  /// feature flag off never touches the native billing SDK at all.
  static Future<void> initialize() async {
    if (!featureEnabled) return;

    _entitlementId =
        dotenv.maybeGet('REVENUECAT_ENTITLEMENT_ID')?.trim().isNotEmpty == true
            ? dotenv.get('REVENUECAT_ENTITLEMENT_ID').trim()
            : 'pro_access';

    final key =
        Platform.isIOS || Platform.isMacOS
            ? dotenv.maybeGet('REVENUECAT_APPLE_KEY')?.trim()
            : Platform.isAndroid
            ? dotenv.maybeGet('REVENUECAT_GOOGLE_KEY')?.trim()
            : null;

    if (key == null || key.isEmpty) {
      _log.w(
        'RevenueCat key missing for this platform — subscriptions disabled. '
        'Pro styles will preview but cannot be purchased.',
      );
      return;
    }

    try {
      await Purchases.setLogLevel(LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(key));
      _available = true;
      _log.i('RevenueCat configured (entitlement: $_entitlementId)');
    } catch (e) {
      _log.e('RevenueCat configure failed — subscriptions disabled', error: e);
    }
  }

  /// Whether the Pro entitlement is currently active.
  static Future<bool> isProActive() async {
    if (!_available) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return _hasPro(info);
    } catch (e) {
      _log.w('Could not read customer info: $e');
      return false;
    }
  }

  /// Available offerings, or null when unavailable.
  static Future<Offerings?> getOfferings() async {
    if (!_available) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      _log.w('Could not fetch offerings: $e');
      return null;
    }
  }

  /// Starts the native purchase flow. Returns whether Pro is now active.
  ///
  /// A user cancelling is a normal outcome, not an error — it returns false
  /// without logging noise.
  static Future<bool> purchasePackage(Package package) async {
    if (!_available) return false;
    try {
      // purchases_flutter 9.0.0 renamed this to purchase(PurchaseParams) and
      // changed the result from CustomerInfo directly to a PurchaseResult
      // wrapping it alongside the StoreTransaction.
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return _hasPro(result.customerInfo);
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      _log.e('Purchase failed', error: e);
      return false;
    } catch (e) {
      _log.e('Purchase failed', error: e);
      return false;
    }
  }

  /// Restores prior purchases. Returns whether Pro is now active.
  static Future<bool> restorePurchases() async {
    if (!_available) return false;
    try {
      final info = await Purchases.restorePurchases();
      return _hasPro(info);
    } catch (e) {
      _log.e('Restore failed', error: e);
      return false;
    }
  }

  /// Subscribes to entitlement changes (renewals, expiry, cross-device sync).
  static void addProStatusListener(void Function(bool isPro) onChanged) {
    if (!_available) return;
    Purchases.addCustomerInfoUpdateListener(
      (info) => onChanged(_hasPro(info)),
    );
  }

  static bool _hasPro(CustomerInfo info) =>
      info.entitlements.active.containsKey(_entitlementId);
}
