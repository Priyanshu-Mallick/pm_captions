/// Languages available when generating captions.
///
/// [storageKey] is persisted and passed through navigation, while
/// [whisperLanguageCode] is the ISO-639-1 code sent to Groq Whisper.
enum CaptionLanguage {
  english('en', 'English', 'en'),
  spanish('es', 'Spanish', 'es'),
  french('fr', 'French', 'fr'),
  german('de', 'German', 'de'),
  portuguese('pt', 'Portuguese', 'pt'),
  italian('it', 'Italian', 'it'),
  japanese('ja', 'Japanese', 'ja'),
  korean('ko', 'Korean', 'ko'),
  chinese('zh', 'Chinese', 'zh'),
  arabic('ar', 'Arabic', 'ar'),
  hindi('hi', 'Hindi', 'hi'),
  hinglish(
    'hinglish',
    'Hinglish (Roman Hindi + English)',
    'hi',
    requiresRomanization: true,
  );

  const CaptionLanguage(
    this.storageKey,
    this.displayName,
    this.whisperLanguageCode, {
    this.requiresRomanization = false,
  });

  final String storageKey;
  final String displayName;
  final String whisperLanguageCode;
  final bool requiresRomanization;

  /// Parses a persisted or routed language value, defaulting safely to English.
  static CaptionLanguage fromStorageKey(String? key) {
    return CaptionLanguage.values.firstWhere(
      (language) => language.storageKey == key,
      orElse: () => CaptionLanguage.english,
    );
  }
}
