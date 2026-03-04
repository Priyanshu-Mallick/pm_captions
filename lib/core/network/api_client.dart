import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Pre-configured [Dio] HTTP client for API calls.
class ApiClient {
  static final _log = Logger();

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
          _log.e(
            'API Error: ${error.response?.statusCode} ${error.message}',
            error: error,
          );
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
