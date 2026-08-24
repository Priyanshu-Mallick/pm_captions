import 'dart:io';

import 'package:dio/dio.dart';

import '../errors/error_reporter.dart';
import '../utils/app_logger.dart';

/// Pre-configured [Dio] HTTP client for API calls.
class ApiClient {
  static final _log = appLogger;

  /// Creates a [Dio] instance configured for the Groq API (free, OpenAI-compatible).
  static Dio create({String? apiKey}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.groq.com/openai/v1/',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 5),
        headers: {if (apiKey != null) 'Authorization': 'Bearer $apiKey'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _log.d('API Request: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _log.d('API Response: ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          final statusCode = error.response?.statusCode;
          _log.e(
            'API Error: $statusCode ${error.message}',
            error: error,
          );
          // 4xx errors are client-side problems (invalid key, bad request) and
          // connection drops (broken pipe, offline, timeouts) are environmental —
          // not app bugs. Skip Sentry for those; the call site handles them.
          final is4xx = statusCode != null && statusCode >= 400 && statusCode < 500;
          final isNetworkDrop = error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError ||
              error.error is SocketException;
          if (!is4xx && !isNetworkDrop) {
            ErrorReporter.captureException(
              error,
              stack: error.stackTrace,
              hint: 'Dio request to ${error.requestOptions.path}',
            );
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
