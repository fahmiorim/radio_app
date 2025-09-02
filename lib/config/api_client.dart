import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_api_config.dart';

class ApiClient {
  ApiClient._internal();
  static final ApiClient I = ApiClient._internal();

  // API (punya /api/mobile)
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppApiConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 120),
      headers: {'Accept': 'application/json'},
    ),
  );

  final Dio dioRoot = Dio(
    BaseOptions(
      baseUrl: AppApiConfig.assetBaseUrl,
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 120),
      headers: {'Accept': 'application/json'},
    ),
  );

  final _storage = const FlutterSecureStorage();
  final CookieJar _cookieJar = CookieJar();
  bool _wired = false;

  void ensureInterceptors() {
    if (_wired) return;
    _wired = true;

    final authInterceptor = InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'user_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // Tambahkan header untuk mencegah caching
        options.headers['Cache-Control'] = 'no-cache';
        options.headers['Pragma'] = 'no-cache';
        handler.next(options);
      },
      onResponse: (response, handler) => handler.next(response),
      onError: (DioException e, handler) async {
        // Handle unauthorized (401) error
        if (e.response?.statusCode == 401) {
          // Hapus token yang tidak valid
          await _storage.delete(key: 'user_token');

          // Navigasi ke halaman login jika diperlukan
          // Catatan: Anda perlu menggunakan navigator key atau event bus untuk ini
          // Contoh: navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        }
        handler.next(e);
      },
    );

    // Tambahkan interceptor untuk menangani error
    final errorInterceptor = InterceptorsWrapper(
      onError: (DioException e, handler) async {
        // Log error untuk debugging
        debugPrint('API Error: ${e.message}');
        debugPrint('URL: ${e.requestOptions.uri}');
        debugPrint('Response: ${e.response?.data}');

        // Handle network errors
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          // Handle timeout errors
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: 'Koneksi timeout. Silakan coba lagi.',
            ),
          );
        }

        return handler.next(e);
      },
    );

    dio.interceptors.addAll([authInterceptor, errorInterceptor]);
    dioRoot.interceptors.addAll([authInterceptor, errorInterceptor]);

    final cookieManager = CookieManager(_cookieJar);
    dio.interceptors.add(cookieManager);
    dioRoot.interceptors.add(CookieManager(_cookieJar));

    dioRoot.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipCsrf'] == true) {
            handler.next(options);
            return;
          }

          var token = await _getCsrfToken();
          if (token == null) {
            await dioRoot.get(
              '/sanctum/csrf-cookie',
              options: Options(extra: {'skipCsrf': true}),
            );
            token = await _getCsrfToken();
          }
          if (token != null) {
            options.headers['X-XSRF-TOKEN'] = token;
            // Beberapa endpoint (seperti /broadcasting/auth) juga
            // mengharapkan header X-CSRF-TOKEN secara eksplisit.
            options.headers['X-CSRF-TOKEN'] = token;
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<String?> _getCsrfToken() async {
    final uri = Uri.parse(AppApiConfig.assetBaseUrl);
    final cookies = await _cookieJar.loadForRequest(uri);
    try {
      final tokenCookie = cookies.firstWhere((c) => c.name == 'XSRF-TOKEN');
      return Uri.decodeComponent(tokenCookie.value);
    } catch (_) {
      return null;
    }
  }
}
