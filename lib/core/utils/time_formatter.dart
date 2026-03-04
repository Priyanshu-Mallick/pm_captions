/// Utility class for formatting [Duration] objects.
class TimeFormatter {
  TimeFormatter._();

  /// Formats a [Duration] to MM:SS display format.
  ///
  /// Example: `Duration(minutes: 1, seconds: 30)` → `"01:30"`
  static String durationToDisplay(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Formats a [Duration] to HH:MM:SS,mmm SRT format.
  ///
  /// Example: `Duration(hours: 0, minutes: 1, seconds: 2, milliseconds: 345)`
  ///   → `"00:01:02,345"`
  static String durationToSrt(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = d.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds,$millis';
  }

  /// Formats a [Duration] to HH:MM:SS.mmm VTT format.
  ///
  /// Example: `Duration(hours: 0, minutes: 1, seconds: 2, milliseconds: 345)`
  ///   → `"00:01:02.345"`
  static String durationToVtt(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = d.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$millis';
  }

  /// Converts a [Duration] to total milliseconds.
  static int durationToMilliseconds(Duration d) => d.inMilliseconds;

  /// Creates a [Duration] from milliseconds.
  static Duration millisecondsToDuration(int ms) => Duration(milliseconds: ms);

  /// Creates a [Duration] from seconds (double).
  static Duration secondsToDuration(double seconds) =>
      Duration(milliseconds: (seconds * 1000).round());

  /// Formats seconds (double) to MM:SS display format.
  static String secondsToDisplay(double seconds) {
    return durationToDisplay(secondsToDuration(seconds));
  }
}
