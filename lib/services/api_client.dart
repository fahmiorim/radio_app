import 'package:dio/dio.dart';

import '../config/app_api_config.dart';

/// Centralized API client using a single [Dio] instance.
class ApiClient {
  ApiClient._();

  /// Shared [Dio] instance configured with base options.
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
}

