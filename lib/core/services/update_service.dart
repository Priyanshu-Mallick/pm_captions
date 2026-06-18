import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:logger/logger.dart';

/// Service managing Android-specific Google Play in-app updates
/// and local force-update simulations.
class UpdateService {
  UpdateService._();

  static final _log = Logger();

  /// Flag to simulate the force update flow during local development and testing.
  /// Set this to `false` for production checks.
  static const bool simulateForceUpdate = false;

  /// The fallback store URL used for the simulated/fallback update screen.
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.pmcaptions.app';

  /// Checks if an update is available on Google Play (or simulates one).
  ///
  /// Returns `true` if an update is required/triggered (and navigation/Google Play UI is shown).
  /// Returns `false` if the app can proceed normally.
  static Future<bool> checkForAndroidUpdate(BuildContext context) async {
    _log.i('Initiating version/update check...');

    if (simulateForceUpdate) {
      _log.i(
        'Force Update Simulation is ACTIVE. Redirecting to blocking screen...',
      );
      if (context.mounted) {
        context.go('/update-required');
      }
      return true;
    }

    // Only run on actual Android devices/emulators
    if (kIsWeb || !Platform.isAndroid) {
      _log.i('In-app update check skipped: Non-Android platform.');
      return false;
    }

    try {
      _log.i('Checking for updates via Google Play Store...');
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        _log.i('Update available! Requesting immediate update flow...');

        // This will launch the official full-screen blocking Play Store update flow
        final result = await InAppUpdate.performImmediateUpdate();
        _log.i('Immediate update result: $result');
        return true;
      } else {
        _log.i('No updates available. App is up-to-date.');
        return false;
      }
    } catch (e) {
      // Catch sideloading issues (Install Error -10: APP_NOT_OWNED) or network issues
      _log.w(
        'Google Play In-App Update check failed/unsupported. Fallback to normal execution.',
        error: e,
      );
      return false;
    }
  }
}
