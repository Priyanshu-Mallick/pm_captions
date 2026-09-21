import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/revenue_cat_service.dart';

/// Tracks whether the user has Pro access and drives the paywall.
///
/// Safe to use when RevenueCat is unconfigured: [isPro] is simply false,
/// [offerings] is null, and the paywall renders its unavailable state.
class SubscriptionProvider extends ChangeNotifier {
  static final _log = Logger();

  static const _debugProKey = 'debug_pro_enabled';

  bool _entitlementActive = false;
  bool _debugPro = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  Offerings? _offerings;
  String? _errorMessage;

  /// Whether Pro features may be exported.
  ///
  /// The debug override feeds the same flag the real entitlement does, so
  /// testing with it exercises the production gating paths.
  bool get isPro => _entitlementActive || _debugPro;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  Offerings? get offerings => _offerings;
  String? get errorMessage => _errorMessage;

  /// Whether purchases can actually be made on this build.
  bool get isStoreAvailable => RevenueCatService.isAvailable;

  /// Whether the debug Pro override is on (always false in release).
  bool get isDebugPro => _debugPro;

  /// The current offering's packages, newest-value-first (annual before
  /// monthly) so the paywall can lead with the better deal.
  List<Package> get packages {
    final current = _offerings?.current;
    if (current == null) return const [];
    final sorted = [...current.availablePackages];
    sorted.sort((a, b) {
      int rank(Package p) => switch (p.packageType) {
        PackageType.annual => 0,
        PackageType.monthly => 1,
        _ => 2,
      };
      return rank(a).compareTo(rank(b));
    });
    return sorted;
  }

  /// Loads entitlement state and offerings. Never throws.
  Future<void> initialize() async {
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      _debugPro = prefs.getBool(_debugProKey) ?? false;
    }

    _entitlementActive = await RevenueCatService.isProActive();

    // A reinstall gets a fresh anonymous RevenueCat ID with no entitlement
    // attached, even though the store subscription is still active and
    // renewing. Without this, a paying user who reinstalls sees "Upgrade to
    // Pro" until they find the Restore button themselves. Silent and
    // best-effort: a network failure here just leaves them at the free tier,
    // same as before this existed, and the Restore button is still there as
    // a manual fallback.
    if (!_entitlementActive) {
      _entitlementActive = await RevenueCatService.restorePurchases();
    }

    _offerings = await RevenueCatService.getOfferings();

    // Renewals, expiry and cross-device restores arrive here.
    RevenueCatService.addProStatusListener((isPro) {
      if (_entitlementActive == isPro) return;
      _entitlementActive = isPro;
      notifyListeners();
    });

    _isInitialized = true;
    notifyListeners();
  }

  /// Runs the purchase flow. Returns whether the user now has Pro.
  Future<bool> purchase(Package package) async {
    _setLoading(true);
    _errorMessage = null;

    final success = await RevenueCatService.purchasePackage(package);
    if (success) {
      _entitlementActive = true;
    } else if (RevenueCatService.isAvailable) {
      // Cancellation also lands here; the paywall stays open either way, so a
      // soft message is the right level of noise.
      _errorMessage = 'Purchase not completed.';
    } else {
      _errorMessage = 'Subscriptions are unavailable on this build.';
    }

    _setLoading(false);
    return isPro;
  }

  /// Restores prior purchases. Returns whether the user now has Pro.
  Future<bool> restore() async {
    _setLoading(true);
    _errorMessage = null;

    final success = await RevenueCatService.restorePurchases();
    if (success) {
      _entitlementActive = true;
    } else {
      _errorMessage =
          RevenueCatService.isAvailable
              ? 'No previous purchases found.'
              : 'Subscriptions are unavailable on this build.';
    }

    _setLoading(false);
    return isPro;
  }

  /// Refreshes offerings, e.g. when opening the paywall after a cold start
  /// where the network was unavailable.
  Future<void> refreshOfferings() async {
    _offerings = await RevenueCatService.getOfferings();
    notifyListeners();
  }

  /// Debug-only Pro simulation, persisted so hot restarts keep it.
  Future<void> toggleDebugPro() async {
    if (!kDebugMode) return;
    _debugPro = !_debugPro;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugProKey, _debugPro);
    _log.i('Debug Pro: $_debugPro');
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
