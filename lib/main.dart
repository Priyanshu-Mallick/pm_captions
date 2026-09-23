import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/constants/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'presentation/providers/video_provider.dart';
import 'presentation/providers/processing_provider.dart';
import 'presentation/providers/caption_provider.dart';
import 'presentation/providers/style_provider.dart';
import 'presentation/providers/export_provider.dart';
import 'presentation/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime HTTP font fetching — all Poppins weights are bundled as
  // assets in google_fonts/. This prevents fatal HandshakeExceptions on
  // restricted networks (e.g. cellular connections with strict TLS policies).
  GoogleFonts.config.allowRuntimeFetching = false;

  // Lock portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Load environment config (tolerate a missing .env so the app still runs).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env bundled — crash reporting stays disabled.
  }

  final sentryDsn = dotenv.maybeGet('SENTRY_DSN') ?? '';

  // Without a DSN there is nothing to report to, so skip Sentry entirely.
  if (sentryDsn.isEmpty) {
    runApp(const AICaptionsApp());
    return;
  }

  // SentryFlutter.init installs FlutterError.onError and a runZonedGuarded
  // zone, capturing uncaught widget + async errors automatically.
  await SentryFlutter.init((options) {
    options.dsn = sentryDsn;
    options.environment = kReleaseMode ? 'production' : 'debug';
    options.debug = !kReleaseMode;
    // Sample a fraction of transactions for performance monitoring.
    options.tracesSampleRate = 0.2;
    // Enable tombstone collection for richer native crash reports
    options.enableTombstone = true;
  }, appRunner: () => runApp(const AICaptionsApp()));

  // // TODO(verify-sentry): Temporary — fires one test event so the Sentry
  // // onboarding "Waiting for error" screen turns green. Remove after verifying.
  // if (!kReleaseMode) {
  //   await Sentry.captureException(
  //     StateError('Sentry verification test exception'),
  //     stackTrace: StackTrace.current,
  //   );
  // }
}

class AICaptionsApp extends StatelessWidget {
  const AICaptionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => ProcessingProvider()),
        ChangeNotifierProvider(create: (_) => CaptionProvider()),
        ChangeNotifierProvider(create: (_) => StyleProvider()),
        ChangeNotifierProvider(create: (_) => ExportProvider()),
      ],
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
