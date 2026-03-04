/// Centralized string constants for the AI Captions app.
///
/// All user-facing text is defined here for easy localization.
class AppStrings {
  AppStrings._();

  // ── App ───────────────────────────────────────────────────────────
  static const String appName = 'AI Captions';
  static const String appTagline = 'Add captions to your videos instantly';

  // ── Home ──────────────────────────────────────────────────────────
  static const String generateAiCaptions = 'Generate AI Captions';
  static const String pickFromGallery = 'Pick from Gallery';
  static const String useCamera = 'Use Camera';
  static const String recentProjects = 'Recent Projects';
  static const String noRecentProjects = 'No recent projects yet';

  // ── Video Picker ──────────────────────────────────────────────────
  static const String selectVideo = 'Select Video';
  static const String videoInfo = 'Video Info';
  static const String duration = 'Duration';
  static const String fileSize = 'File Size';
  static const String language = 'Language';
  static const String apiKey = 'API Key';
  static const String apiKeyHint = 'Enter your free Groq API key (gsk_...)';
  static const String apiKeyLink = 'Get free key at console.groq.com';
  static const String generateCaptions = 'Generate Captions';
  static const String selectLanguage = 'Select Language';

  // ── Processing ────────────────────────────────────────────────────
  static const String processing = 'Processing';
  static const String extractingAudio = 'Extracting audio...';
  static const String transcribingSpeech =
      'Transcribing speech with Groq Whisper AI...';
  static const String generatingCaptions = 'Generating captions...';
  static const String finalizing = 'Finalizing...';
  static const String cancel = 'Cancel';
  static const String retry = 'Retry';

  // ── Editor ────────────────────────────────────────────────────────
  static const String captions = 'Captions';
  static const String style = 'Style';
  static const String timing = 'Timing';
  static const String addCaption = '+ Add Caption';
  static const String editCaption = 'Edit Caption';
  static const String deleteCaption = 'Delete Caption';
  static const String exportVideo = 'Export';
  static const String undo = 'Undo';
  static const String redo = 'Redo';
  static const String unsavedChanges = 'You have unsaved changes. Discard?';

  // ── Style Panel ───────────────────────────────────────────────────
  static const String templates = 'Templates';
  static const String fontFamily = 'Font Family';
  static const String fontSize = 'Font Size';
  static const String textColor = 'Text Color';
  static const String highlightColor = 'Highlight Color';
  static const String backgroundColor = 'Background';
  static const String backgroundOpacity = 'Opacity';
  static const String borderRadius = 'Border Radius';
  static const String textStroke = 'Text Stroke';
  static const String shadow = 'Shadow';
  static const String position = 'Position';
  static const String wordsPerLine = 'Words Per Line';
  static const String animation = 'Animation';
  static const String allCaps = 'ALL CAPS';

  // ── Export ────────────────────────────────────────────────────────
  static const String exportOptions = 'Export Options';
  static const String videoWithCaptions = 'Video with Captions (MP4)';
  static const String srtFile = 'SRT Subtitle File';
  static const String vttFile = 'VTT Subtitle File';
  static const String videoAndSrt = 'Video + SRT';
  static const String quality = 'Quality';
  static const String original = 'Original';
  static const String exporting = 'Exporting...';
  static const String exportComplete = 'Export Complete!';
  static const String saveToGallery = 'Save to Gallery';
  static const String share = 'Share';

  // ── Settings ──────────────────────────────────────────────────────
  static const String settings = 'Settings';
  static const String apiKeyConfig = 'Groq API Key (Free)';
  static const String testConnection = 'Test Connection';
  static const String getApiKey = 'Get API Key';
  static const String defaultLanguage = 'Default Language';
  static const String defaultTemplate = 'Default Template';
  static const String storage = 'Storage';
  static const String clearAllProjects = 'Clear All Projects';
  static const String about = 'About';
  static const String appVersion = 'Version 1.0.0';
  static const String privacyPolicy = 'Privacy Policy';

  // ── Errors ────────────────────────────────────────────────────────
  static const String noApiKeyMessage =
      'Please add your free Groq API key in Settings. Get one at console.groq.com';
  static const String networkErrorMessage =
      'No internet connection. Please check your network.';
  static const String apiErrorMessage =
      'Transcription failed. Please try again.';
  static const String audioExtractionError =
      'Could not extract audio from this video file.';
  static const String ffmpegError =
      'Video processing failed. Please try a different video.';
  static const String unsupportedFormat = 'This video format is not supported.';
  static const String fileTooLarge =
      'Video file is too large. Maximum size is 500MB.';
  static const String insufficientStorage =
      'Not enough storage space to export video.';
  static const String videoTooLong =
      'Video is too long. Maximum length is 10 minutes.';
  static const String permissionDenied = 'Storage permission is required.';
  static const String genericError = 'Something went wrong. Please try again.';

  // ── Languages ─────────────────────────────────────────────────────
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'pt': 'Portuguese',
    'it': 'Italian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
    'ar': 'Arabic',
    'hi': 'Hindi',
  };

  // ── Onboarding ────────────────────────────────────────────────────
  static const String onboardingTitle1 = 'Add AI Captions';
  static const String onboardingDesc1 =
      'Automatically generate accurate captions for your videos using Whisper AI';
  static const String onboardingTitle2 = 'Customize Styles';
  static const String onboardingDesc2 =
      'Choose from beautiful templates or create your own caption style';
  static const String onboardingTitle3 = 'Export & Share';
  static const String onboardingDesc3 =
      'Export videos with burned-in captions or download subtitle files';
  static const String getStarted = 'Get Started';
  static const String next = 'Next';
  static const String skip = 'Skip';
}
