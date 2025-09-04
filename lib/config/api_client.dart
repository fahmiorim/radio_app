import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'app_api_config.dart';

class ApiClient {
  ApiClient._internal();
  static final ApiClient I = ApiClient._internal();

  late final Dio dio; // untuk endpoint /api/mobile
  late final Dio dioRoot; // untuk root host (file, csrf, broadcasting, dll)
  late final CookieJar _cookieJar;

  // supaya nggak dobel wiring
  bool _wired = false;

  /// Panggil sekali saat startup, setelah dotenv.load()
  Future<void> ensureInterceptors() async {
    if (_wired) return;
    _wired = true;

    // ====== Inisialisasi Dio clients ======
    dio = Dio(
      BaseOptions(
        baseUrl: AppApiConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
        // 2xx saja yang dianggap success → 401/403/422/5xx akan masuk onError
        validateStatus: (c) => c != null && c >= 200 && c < 300,
      ),
    );

    dioRoot = Dio(
      BaseOptions(
        baseUrl: AppApiConfig.assetBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
        validateStatus: (c) => c != null && c >= 200 && c < 300,
      ),
    );

    // ====== Cookie storage (persisten) ======
    final dir = await _cookiesDir();
    _cookieJar = PersistCookieJar(storage: FileStorage(dir.path));
    final cookieMgr = CookieManager(_cookieJar);
    dio.interceptors.add(cookieMgr);
    dioRoot.interceptors.add(cookieMgr);

    // ====== Authorization & no-cache ======
    final authInterceptor = InterceptorsWrapper(
      onRequest: (options, handler) async {
        // cache-control
        options.headers['Cache-Control'] = 'no-cache';
        options.headers['Pragma'] = 'no-cache';
        handler.next(options);
      },
      onResponse: (response, handler) => handler.next(response),
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          // bisa lakukan aksi global (hapus token, navigate login) di sini
          // NOTE: token header dikelola via setBearer()/clearBearer()
        }
        handler.next(e);
      },
    );
    dio.interceptors.add(authInterceptor);
    dioRoot.interceptors.add(authInterceptor);

    // ====== Logging (debug only) ======
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: false,
          responseHeader: false,
        ),
      );
      dioRoot.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: false,
          responseHeader: false,
        ),
      );
    }

    // ====== Bypass baseUrl untuk URL absolut ======
    final absUrlBypass = InterceptorsWrapper(
      onRequest: (options, handler) {
        final p = options.path;
        if (p.startsWith('http://') || p.startsWith('https://')) {
          // jangan gabungkan dengan baseUrl
          options.baseUrl = '';
        }
        handler.next(options);
      },
    );
    dio.interceptors.add(absUrlBypass);
    dioRoot.interceptors.add(absUrlBypass);

    // ====== CSRF untuk Sanctum di dioRoot ======
    dioRoot.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // hanya suntik CSRF untuk host yang sama (ASSET_BASE_URL)
          final reqUri = Uri.parse(AppApiConfig.assetBaseUrl);
          final optUri = Uri.parse('${dioRoot.options.baseUrl}${options.path}');
          final sameHost =
              (optUri.host == reqUri.host &&
              optUri.scheme == reqUri.scheme &&
              optUri.port == reqUri.port);

          if (!sameHost || options.extra['skipCsrf'] == true) {
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
          }
          handler.next(options);
        },
      ),
    );
  }

  /// Set Authorization Bearer ke KEDUA client
  void setBearer(String token) {
    final v = 'Bearer $token';
    dio.options.headers['Authorization'] = v;
    dioRoot.options.headers['Authorization'] = v;
  }

  /// Hapus Authorization
  void clearBearer() {
    dio.options.headers.remove('Authorization');
    dioRoot.options.headers.remove('Authorization');
  }

  Future<Directory> _cookiesDir() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}${Platform.pathSeparator}cookies');
    if (!(await dir.exists())) await dir.create(recursive: true);
    return dir;
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
