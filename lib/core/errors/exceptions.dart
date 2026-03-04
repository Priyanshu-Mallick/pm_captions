/// Custom exception hierarchy for the AI Captions app.
///
/// All exceptions extend [AppException] and provide both a technical
/// message and a user-friendly message for display.
abstract class AppException implements Exception {
  /// Technical error message for logging.
  String get message;

  /// User-friendly message suitable for display in UI.
  String get userFriendlyMessage;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when no OpenAI API key is configured.
class NoApiKeyException extends AppException {
  @override
  String get message => 'No API key configured';

  @override
  String get userFriendlyMessage =>
      'Please configure your OpenAI API key in settings';
}

/// Thrown when the device has no internet connection.
class NetworkException extends AppException {
  final String? details;

  NetworkException({this.details});

  @override
  String get message => 'Network error: ${details ?? "No connection"}';

  @override
  String get userFriendlyMessage =>
      'No internet connection. Please check your network.';
}

/// Thrown when the API returns an error response.
class ApiException extends AppException {
  final int? statusCode;
  final String? responseBody;

  ApiException({this.statusCode, this.responseBody});

  @override
  String get message => 'API error: statusCode=$statusCode, body=$responseBody';

  @override
  String get userFriendlyMessage =>
      'Transcription failed. Please try again. (Error $statusCode)';
}

/// Thrown when audio extraction from video fails.
class AudioExtractionException extends AppException {
  final String? details;

  AudioExtractionException({this.details});

  @override
  String get message => 'Audio extraction failed: ${details ?? "unknown"}';

  @override
  String get userFriendlyMessage =>
      'Could not extract audio from this video file.';
}

/// Thrown when an FFmpeg operation fails.
class FFmpegException extends AppException {
  final String? command;
  final int? returnCode;

  FFmpegException({this.command, this.returnCode});

  @override
  String get message =>
      'FFmpeg error: command=$command, returnCode=$returnCode';

  @override
  String get userFriendlyMessage =>
      'Video processing failed. Please try a different video.';
}

/// Thrown when the video format is not supported.
class UnsupportedVideoFormatException extends AppException {
  final String? format;

  UnsupportedVideoFormatException({this.format});

  @override
  String get message => 'Unsupported video format: $format';

  @override
  String get userFriendlyMessage => 'This video format is not supported.';
}

/// Thrown when the video file exceeds the maximum size.
class FileSizeException extends AppException {
  final int? sizeMB;

  FileSizeException({this.sizeMB});

  @override
  String get message => 'File too large: ${sizeMB}MB';

  @override
  String get userFriendlyMessage =>
      'Video file is too large. Maximum size is 500MB.';
}

/// Thrown when there is not enough storage space.
class InsufficientStorageException extends AppException {
  @override
  String get message => 'Insufficient storage';

  @override
  String get userFriendlyMessage => 'Not enough storage space to export video.';
}

/// Thrown when the video exceeds the maximum duration.
class VideoTooLongException extends AppException {
  final Duration? duration;

  VideoTooLongException({this.duration});

  @override
  String get message => 'Video too long: $duration';

  @override
  String get userFriendlyMessage =>
      'Video is too long. Maximum length is 10 minutes.';
}

/// Thrown when a required permission is denied.
class PermissionDeniedException extends AppException {
  final String? permission;

  PermissionDeniedException({this.permission});

  @override
  String get message => 'Permission denied: $permission';

  @override
  String get userFriendlyMessage => 'Storage permission is required.';
}

/// Thrown when a generic/unexpected error occurs.
class GenericException extends AppException {
  final String? details;

  GenericException({this.details});

  @override
  String get message => 'Generic error: ${details ?? "unknown"}';

  @override
  String get userFriendlyMessage => 'Something went wrong. Please try again.';
}
