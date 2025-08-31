// lib/config/api_client.dart
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_api_config.dart';

class ApiClient {
  ApiClient._internal();
  static final ApiClient I = ApiClient._internal();

  // API (punya /api/mobile)
  final Dio dio = Dio(
    BaseOptions(
      baseUrl:
          AppApiConfig.apiBaseUrl, // ex: http://192.168.1.7:8000/api/mobile
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 120),
      headers: {'Accept': 'application/json'},
    ),
  );

  // ROOT (tanpa /api/mobile) — untuk live-chat & broadcasting/auth
  final Dio dioRoot = Dio(
    BaseOptions(
      baseUrl: AppApiConfig.assetBaseUrl, // ex: http://192.168.1.7:8000
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
        handler.next(options);
      },
      onResponse: (response, handler) => handler.next(response),
      onError: (e, handler) => handler.next(e),
    );

    dio.interceptors.add(authInterceptor);
    dioRoot.interceptors.add(authInterceptor); // << penting: ROOT juga bawa Bearer

    // Cookie management
    final cookieManager = CookieManager(_cookieJar);
    dio.interceptors.add(cookieManager);
    dioRoot.interceptors.add(CookieManager(_cookieJar));

    // CSRF token handling for ROOT requests
    dioRoot.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipCsrf'] == true) {
            handler.next(options);
            return;
          }

          var token = await _getCsrfToken();
          if (token == null) {
            await dioRoot.get('/sanctum/csrf-cookie',
                options: Options(extra: {'skipCsrf': true}));
            token = await _getCsrfToken();
          }
          if (token != null) {
            options.headers['X-XSRF-TOKEN'] = token;
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
      final tokenCookie =
          cookies.firstWhere((c) => c.name == 'XSRF-TOKEN');
      return Uri.decodeComponent(tokenCookie.value);
    } catch (_) {
      return null;
    }
  }
}
