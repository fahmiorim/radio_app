import 'package:dio/dio.dart';
import 'app_api_config.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );
}
