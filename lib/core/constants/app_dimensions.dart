/// Centralized dimension constants for the AI Captions app.
///
/// All spacing, radius, and sizing values are defined here for
/// consistent layout across the entire app.
class AppDimensions {
  AppDimensions._();

  // ── Padding ───────────────────────────────────────────────────────
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // ── Margin ────────────────────────────────────────────────────────
  static const double marginXS = 4.0;
  static const double marginSM = 8.0;
  static const double marginMD = 16.0;
  static const double marginLG = 24.0;
  static const double marginXL = 32.0;

  // ── Border Radius ─────────────────────────────────────────────────
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 100.0;

  // ── Icon Sizes ────────────────────────────────────────────────────
  static const double iconSM = 16.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;

  // ── Button ────────────────────────────────────────────────────────
  static const double buttonHeight = 52.0;
  static const double buttonHeightSM = 40.0;
  static const double buttonRadius = 12.0;

  // ── Card ──────────────────────────────────────────────────────────
  static const double cardRadius = 16.0;
  static const double cardElevation = 4.0;
  static const double cardPadding = 16.0;

  // ── Thumbnail ─────────────────────────────────────────────────────
  static const double thumbnailWidth = 120.0;
  static const double thumbnailHeight = 80.0;

  // ── Caption ───────────────────────────────────────────────────────
  static const double captionMinFontSize = 12.0;
  static const double captionMaxFontSize = 48.0;
  static const double captionDefaultFontSize = 22.0;
  static const int captionMaxChars = 100;
  static const int captionMinWordsPerLine = 2;
  static const int captionMaxWordsPerLine = 8;
  static const int captionDefaultWordsPerLine = 5;

  // ── Video ─────────────────────────────────────────────────────────
  static const double videoPreviewRatio = 0.5;
  static const double timelineHeight = 60.0;

  // ── Layout ────────────────────────────────────────────────────────
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 56.0;
  static const double tabBarHeight = 48.0;

  // ── Constraints ───────────────────────────────────────────────────
  static const int maxFileSizeMB = 500;
  static const int maxVideoDurationMinutes = 10;
  static const int maxUndoSteps = 20;
  static const double minCaptionDurationSec = 0.5;
}
