import 'package:equatable/equatable.dart';

/// Failure representation using functional error handling.
///
/// Used with Either types to return failures without throwing exceptions.
abstract class Failure extends Equatable {
  final String message;
  final String userFriendlyMessage;

  const Failure({required this.message, required this.userFriendlyMessage});

  @override
  List<Object> get props => [message];
}

/// Failure from server / API errors.
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.userFriendlyMessage = 'Server error. Please try again.',
  });
}

/// Failure from network / connectivity issues.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
    super.userFriendlyMessage =
        'No internet connection. Please check your network.',
  });
}

/// Failure from local storage / database operations.
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.userFriendlyMessage = 'Local storage error.',
  });
}

/// Failure from file system operations.
class FileFailure extends Failure {
  const FileFailure({
    required super.message,
    super.userFriendlyMessage = 'File operation failed.',
  });
}

/// Failure from FFmpeg operations.
class ProcessingFailure extends Failure {
  const ProcessingFailure({
    required super.message,
    super.userFriendlyMessage = 'Video processing failed.',
  });
}

/// Failure from permission denial.
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.userFriendlyMessage = 'Permission is required.',
  });
}
