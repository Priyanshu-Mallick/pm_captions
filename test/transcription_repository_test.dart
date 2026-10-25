import 'package:flutter_test/flutter_test.dart';
import 'package:pm_captions/core/constants/caption_language.dart';
import 'package:pm_captions/data/datasources/hinglish_transliteration_service.dart';
import 'package:pm_captions/data/datasources/whisper_datasource.dart';
import 'package:pm_captions/data/models/caption_style_model.dart';
import 'package:pm_captions/data/models/word_timestamp_model.dart';
import 'package:pm_captions/data/repositories/transcription_repository.dart';

void main() {
  test('normal language uses its Whisper code and skips conversion', () async {
    final speech = _FakeSpeechDatasource(_nativeResult());
    final transliterator = _FakeTransliterator(const []);
    final repository = TranscriptionRepository(
      datasource: speech,
      hinglishService: transliterator,
    );

    final result = await repository.transcribe(
      'audio.wav',
      language: CaptionLanguage.english,
    );

    expect(speech.requestedLanguage, 'en');
    expect(transliterator.callCount, 0);
    expect(result.rawWords.single.word, 'hello');
  });

  test('Hinglish transcribes as Hindi then converts before grouping', () async {
    final native = _nativeResult(word: 'आज');
    final romanWords = [native.rawWords.single.copyWith(word: 'aaj')];
    final speech = _FakeSpeechDatasource(native);
    final transliterator = _FakeTransliterator(romanWords);
    final repository = TranscriptionRepository(
      datasource: speech,
      hinglishService: transliterator,
    );
    var conversionStarted = false;

    final result = await repository.transcribe(
      'audio.wav',
      language: CaptionLanguage.hinglish,
      onHinglishConversionStarted: () => conversionStarted = true,
    );

    expect(speech.requestedLanguage, 'hi');
    expect(conversionStarted, isTrue);
    expect(transliterator.callCount, 1);
    expect(result.rawWords.single.word, 'aaj');
    expect(result.captions.single.text, 'aaj');
    expect(result.captions.single.words.single.start, 0.1);
  });
}

TranscriptionResult _nativeResult({String word = 'hello'}) {
  return TranscriptionResult(
    captions: const [],
    rawWords: [
      WordTimestampModel(word: word, start: 0.1, end: 0.4, confidence: 0.9),
    ],
    detectedLanguage: 'hi',
  );
}

class _FakeSpeechDatasource implements SpeechToTextDatasource {
  _FakeSpeechDatasource(this.result);

  final TranscriptionResult result;
  String? requestedLanguage;

  @override
  Future<TranscriptionResult> transcribeAudio(
    String audioPath, {
    String? language,
    CaptionStyleModel style = const CaptionStyleModel(),
  }) async {
    requestedLanguage = language;
    return result;
  }
}

class _FakeTransliterator implements HinglishTransliterationService {
  _FakeTransliterator(this.result);

  final List<WordTimestampModel> result;
  int callCount = 0;

  @override
  Future<List<WordTimestampModel>> transliterate(
    List<WordTimestampModel> words,
  ) async {
    callCount++;
    return result;
  }
}
