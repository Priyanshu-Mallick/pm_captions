import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../errors/error_reporter.dart';

/// Shared application [Logger].
///
/// Behaves like a normal `logger` instance (console output in debug) but also
/// forwards every log line to Sentry as a breadcrumb, so each crash/exception
/// report carries the trail of recent log lines leading up to it.
///
/// Use this everywhere instead of constructing `Logger()` directly.
final Logger appLogger = Logger(output: _SentryBreadcrumbOutput());

/// A [LogOutput] that prints to the console (in debug) and mirrors each log
/// event into a Sentry breadcrumb.
class _SentryBreadcrumbOutput extends LogOutput {
  final ConsoleOutput _console = ConsoleOutput();

  @override
  void output(OutputEvent event) {
    // Keep normal console behaviour.
    _console.output(event);

    // Forward to Sentry as a breadcrumb.
    final message = event.origin.message?.toString() ?? event.lines.join('\n');
    ErrorReporter.addBreadcrumb(
      message,
      category: 'log',
      level: _toSentryLevel(event.level),
    );
  }

  SentryLevel _toSentryLevel(Level level) {
    switch (level) {
      case Level.error:
      case Level.fatal:
        return SentryLevel.error;
      case Level.warning:
        return SentryLevel.warning;
      case Level.debug:
      case Level.trace:
        return SentryLevel.debug;
      default:
        return SentryLevel.info;
    }
  }
}
