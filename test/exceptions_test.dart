import 'package:flutter_test/flutter_test.dart';
import 'package:pm_captions/core/errors/exceptions.dart';

void main() {
  group('Exceptions', () {
    test('NoAudioTrackException has correct messages', () {
      final exception = NoAudioTrackException();
      expect(exception.message, contains('no audio track'));
      expect(exception.userFriendlyMessage, contains('no audio track'));
    });

    test('CancellationException has correct messages', () {
      final exception = CancellationException();
      expect(exception.message, contains('cancelled'));
      expect(exception.userFriendlyMessage, contains('cancelled'));
    });

    test('AudioExtractionException has correct messages', () {
      final exception = AudioExtractionException(details: 'FFmpeg return code: 255');
      expect(exception.message, contains('FFmpeg return code: 255'));
      expect(exception.userFriendlyMessage, contains('Could not extract audio'));
    });
  });
}
