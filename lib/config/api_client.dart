import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_api_config.dart';

class ApiClient {
  ApiClient._internal();
  static final ApiClient I = ApiClient._internal();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppApiConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 120),
      headers: {'Accept': 'application/json'},
    ),
  );

  final _storage = const FlutterSecureStorage();
  bool _wired = false;

  void ensureInterceptors() {
    if (_wired) return;
    _wired = true;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'user_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            debugPrint('➡️  ${options.method} ${options.uri}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '✅ ${response.statusCode} ${response.requestOptions.uri}',
            );
          }
          handler.next(response);
        },
        onError: (e, handler) {
          if (kDebugMode) {
            debugPrint(
              '❌ ${e.response?.statusCode} ${e.requestOptions.uri} :: ${e.message}',
            );
          }
          handler.next(e);
        },
      ),
    );
  }
}
