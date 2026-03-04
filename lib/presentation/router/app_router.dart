import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/video_picker/video_picker_screen.dart';
import '../screens/processing/processing_screen.dart';
import '../screens/editor/caption_editor_screen.dart';
import '../screens/export/export_screen.dart';
import '../screens/settings/settings_screen.dart';

/// Application router configuration using go_router.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/video-picker',
      builder: (context, state) => const VideoPickerScreen(),
    ),
    GoRoute(
      path: '/processing',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ProcessingScreen(
          videoPath: extra['videoPath'] as String,
          apiKey: extra['apiKey'] as String,
          language: extra['language'] as String,
        );
      },
    ),
    GoRoute(
      path: '/editor/:projectId',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId']!;
        return CaptionEditorScreen(projectId: projectId);
      },
    ),
    GoRoute(
      path: '/export/:projectId',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId']!;
        return ExportScreen(projectId: projectId);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
