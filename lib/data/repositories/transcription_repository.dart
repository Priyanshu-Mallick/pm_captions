import 'package:logger/logger.dart';

import '../../core/constants/caption_language.dart';
import '../../core/utils/caption_parser_utils.dart';
import '../datasources/hinglish_transliteration_service.dart';
import '../datasources/whisper_datasource.dart';
import '../models/caption_model.dart';
import '../models/caption_style_model.dart';
import '../models/word_timestamp_model.dart';

/// Repository for transcription operations.
///
/// Abstracts the speech-to-text datasource and provides methods
/// for transcribing audio and managing transcription results.
class TranscriptionRepository {
  final SpeechToTextDatasource _datasource;
  final HinglishTransliterationService _hinglishService;
  static final _log = Logger();

  TranscriptionRepository({
    SpeechToTextDatasource? datasource,
    HinglishTransliterationService? hinglishService,
  }) : _datasource = datasource ?? WhisperDatasource(),
       _hinglishService =
           hinglishService ?? GroqHinglishTransliterationService();

  /// Transcribes an audio file and returns captions.
  Future<TranscriptionResult> transcribe(
    String audioPath, {
    required CaptionLanguage language,
    CaptionStyleModel style = const CaptionStyleModel(),
    void Function()? onHinglishConversionStarted,
  }) async {
    _log.i(
      'Starting transcription for: $audioPath, '
      'language: ${language.storageKey}',
    );
    final result = await _datasource.transcribeAudio(
      audioPath,
      language: language.whisperLanguageCode,
      style: style,
    );

    if (!language.requiresRomanization || result.rawWords.isEmpty) {
      return result;
    }

    onHinglishConversionStarted?.call();
    final convertedWords = await _hinglishService.transliterate(
      result.rawWords,
    );
    return TranscriptionResult(
      captions: CaptionParserUtils.groupWordsIntoCaptions(
        convertedWords,
        style,
      ),
      rawWords: convertedWords,
      detectedLanguage: result.detectedLanguage,
    );
  }

  /// Re-groups existing words into captions with a new style.
  List<CaptionModel> regroupCaptions(
    List<WordTimestampModel> words,
    CaptionStyleModel style,
  ) {
    return CaptionParserUtils.groupWordsIntoCaptions(words, style);
  }
}
