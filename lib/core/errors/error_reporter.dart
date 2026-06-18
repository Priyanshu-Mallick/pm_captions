import 'package:sentry_flutter/sentry_flutter.dart';

import 'exceptions.dart';

/// Thin wrapper around Sentry so the rest of the app never imports
/// `sentry_flutter` directly.
///
/// All calls are safe no-ops when Sentry is not initialized (e.g. local dev
/// without a `SENTRY_DSN`), so call sites don't need to guard on configuration.
class ErrorReporter {
  ErrorReporter._();

  /// Reports a handled (non-fatal) exception to Sentry.
  ///
  /// For [AppException]s, the technical [AppException.message] is sent as the
  /// error and the [AppException.userFriendlyMessage] is attached as extra
  /// context so dashboards show both.
  static Future<void> captureException(
    Object error, {
    StackTrace? stack,
    String? hint,
  }) async {
    await Sentry.captureException(
      error,
      stackTrace: stack,
      hint: hint == null ? null : Hint.withMap({'context': hint}),
      withScope: (scope) {
        if (error is AppException) {
          scope.setContexts('app_exception', {
            'type': error.runtimeType.toString(),
            'message': error.message,
            'user_message': error.userFriendlyMessage,
          });
        }
      },
    );
  }

  /// Adds a breadcrumb describing something that happened, so it shows up in
  /// the trail leading up to a later crash/exception.
  static void addBreadcrumb(
    String message, {
    String? category,
    SentryLevel level = SentryLevel.info,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(message: message, category: category, level: level),
    );
  }
}
