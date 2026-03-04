import 'package:flutter/material.dart';

/// Centralized color constants for the AI Captions app.
///
/// All colors used throughout the app are defined here to ensure
/// consistency and easy theming.
class AppColors {
  AppColors._();

  // ── Background & Surface ──────────────────────────────────────────
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color card = Color(0xFF16213E);
  static const Color cardLight = Color(0xFF1E2D4A);

  // ── Brand ─────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFE94560);
  static const Color secondary = Color(0xFF0F3460);
  static const Color accent = Color(0xFF533483);

  // ── Text ──────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C3);
  static const Color textHint = Color(0xFF6B6B80);

  // ── Status ────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00D9A5);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF4757);

  // ── Gradients ─────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFF0F0F1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [card, Color(0xFF1A2744)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Caption defaults ──────────────────────────────────────────────
  static const Color captionText = Colors.white;
  static const Color captionHighlight = Color(0xFFFFD700);
  static const Color captionBackground = Color(0x99000000);
  static const Color captionStroke = Colors.black;

  // ── Misc ──────────────────────────────────────────────────────────
  static const Color divider = Color(0xFF2A2A3E);
  static const Color shimmerBase = Color(0xFF1A1A2E);
  static const Color shimmerHighlight = Color(0xFF2A2A40);
  static const Color overlay = Color(0xCC000000);
}
