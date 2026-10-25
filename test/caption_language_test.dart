import 'package:flutter_test/flutter_test.dart';
import 'package:pm_captions/core/constants/caption_language.dart';

void main() {
  group('CaptionLanguage', () {
    test('has unique stable storage keys and valid Whisper codes', () {
      final keys = CaptionLanguage.values.map(
        (language) => language.storageKey,
      );

      expect(keys.toSet(), hasLength(CaptionLanguage.values.length));
      for (final language in CaptionLanguage.values) {
        expect(language.displayName, isNotEmpty);
        expect(language.whisperLanguageCode, matches(RegExp(r'^[a-z]{2}$')));
      }
    });

    test('maps Hinglish to Hindi for Whisper and enables romanization', () {
      expect(CaptionLanguage.hinglish.storageKey, 'hinglish');
      expect(CaptionLanguage.hinglish.whisperLanguageCode, 'hi');
      expect(CaptionLanguage.hinglish.requiresRomanization, isTrue);
    });

    test('round-trips supported keys and falls back to English', () {
      for (final language in CaptionLanguage.values) {
        expect(CaptionLanguage.fromStorageKey(language.storageKey), language);
      }

      expect(CaptionLanguage.fromStorageKey(null), CaptionLanguage.english);
      expect(
        CaptionLanguage.fromStorageKey('obsolete-language'),
        CaptionLanguage.english,
      );
    });
  });
}
