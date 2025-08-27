import 'package:dio/dio.dart';
import 'app_api_config.dart';

class ApiClient {
  static final Dio _dio = Dio();
  
  static Dio get dio {
    _dio.options = BaseOptions(
      baseUrl: AppApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 120),
      headers: {'Accept': 'application/json'},
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('Sending request to ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('Response from ${response.requestOptions.uri}: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('Error from ${e.requestOptions.uri}: ${e.message}');
          return handler.next(e);
        },
      ),
    );

    return _dio;
  }
}
