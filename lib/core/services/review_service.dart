import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Service managing in-app rating/review flows.
class ReviewService {
  ReviewService._();

  static final _log = Logger();
  static const String _hasRatedKey = 'has_rated_app';

  /// Triggers the in-app review dialog if the user has not yet completed a rating.
  ///
  /// Once requested, the flag is saved locally so the user is not prompted again.
  static Future<void> triggerInAppReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRated = prefs.getBool(_hasRatedKey) ?? false;

      if (hasRated) {
        _log.i('In-App Review skipped: User has already rated the app.');
        return;
      }

      final inAppReview = InAppReview.instance;
      _log.i('Checking in-app review availability...');
      
      final isAvailable = await inAppReview.isAvailable();
      if (isAvailable) {
        _log.i('Requesting in-app review...');
        // Request the native rating/review dialog
        await inAppReview.requestReview();
        
        // Save flag to prevent future prompts
        await prefs.setBool(_hasRatedKey, true);
        _log.i('In-app review requested successfully. Flag updated in preferences.');
      } else {
        _log.w('In-app review is not available on this device.');
      }
    } catch (e) {
      _log.e('Failed to trigger in-app review', error: e);
    }
  }

  /// Helper method to reset the rating flag for manual testing/development.
  static Future<void> resetRatingFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasRatedKey);
    _log.i('In-app review preference key reset.');
  }
}
