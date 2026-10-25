import 'package:flutter_test/flutter_test.dart';
import 'package:pm_captions/core/constants/caption_language.dart';
import 'package:pm_captions/core/errors/exceptions.dart';
import 'package:pm_captions/data/datasources/hinglish_transliteration_service.dart';
import 'package:pm_captions/data/datasources/whisper_datasource.dart';
import 'package:pm_captions/data/models/caption_style_model.dart';
import 'package:pm_captions/data/models/word_timestamp_model.dart';
import 'package:pm_captions/data/repositories/transcription_repository.dart';
import 'package:pm_captions/presentation/providers/processing_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Hinglish processing exposes conversion state before completion',
    () async {
      final repository = TranscriptionRepository(
        datasource: _SpeechDatasource(),
        hinglishService: _SuccessfulTransliterator(),
      );
      final provider = ProcessingProvider(
        transcriptionRepo: repository,
        audioExtractor: (_) async => 'audio.wav',
      );
      final states = <ProcessingState>[];
      provider.addListener(() => states.add(provider.currentState));

      await provider.startProcessing(
        videoPath: 'video.mp4',
        apiKey: 'gsk_${'x' * 40}',
        language: CaptionLanguage.hinglish,
      );

      expect(provider.isHinglishProcessing, isTrue);
      expect(states, contains(ProcessingState.convertingToHinglish));
      expect(provider.currentState, ProcessingState.done);
      expect(provider.captions.single.text, 'aaj');
    },
  );

  test('conversion failure stops in retryable error state', () async {
    final repository = TranscriptionRepository(
      datasource: _SpeechDatasource(),
      hinglishService: _FailingTransliterator(),
    );
    final provider = ProcessingProvider(
      transcriptionRepo: repository,
      audioExtractor: (_) async => 'audio.wav',
    );

    await provider.startProcessing(
      videoPath: 'video.mp4',
      apiKey: 'gsk_${'x' * 40}',
      language: CaptionLanguage.hinglish,
    );

    expect(provider.currentState, ProcessingState.error);
    expect(provider.errorMessage, contains('Roman Hinglish'));
    expect(provider.captions, isEmpty);
  });
}

class _SpeechDatasource implements SpeechToTextDatasource {
  @override
  Future<TranscriptionResult> transcribeAudio(
    String audioPath, {
    String? language,
    CaptionStyleModel style = const CaptionStyleModel(),
  }) async {
    return const TranscriptionResult(
      captions: [],
      rawWords: [WordTimestampModel(word: 'आज', start: 0.0, end: 0.5)],
      detectedLanguage: 'hi',
    );
  }
}

class _SuccessfulTransliterator implements HinglishTransliterationService {
  @override
  Future<List<WordTimestampModel>> transliterate(
    List<WordTimestampModel> words,
  ) async {
    return [words.single.copyWith(word: 'aaj')];
  }
}

class _FailingTransliterator implements HinglishTransliterationService {
  @override
  Future<List<WordTimestampModel>> transliterate(
    List<WordTimestampModel> words,
  ) async {
    throw HinglishConversionException(details: 'invalid response');
  }
}
