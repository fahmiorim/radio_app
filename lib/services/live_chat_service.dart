import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_client.dart';
import '../models/live_message_model.dart';
import '../models/live_status_model.dart';

class LiveChatService {
  LiveChatService._();
  static final LiveChatService I = LiveChatService._();

  final Dio _dio = ApiClient.I.dioRoot;

  Future<List<LiveChatMessage>> fetchMessages(int id) async {
    try {
      ApiClient.I.ensureInterceptors();

      final token = await const FlutterSecureStorage().read(key: 'user_token');
      print('🔑 Auth token: ${token != null ? 'Present' : 'Missing'}');

      // Make the request
      final response = await _dio.get<dynamic>(
        '/live-chat/$id/fetch',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) =>
              status! < 500, // Don't throw for 500 errors
        ),
      );

      print('✅ [LiveChatService] Response status: ${response.statusCode}');

      // Parse response
      if (response.statusCode == 200) {
        print('📦 Response data: ${response.data}');

        // Handle the response format: {"success": true, "data": [...]}
        final Map<String, dynamic> responseData = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : {};

        if (responseData['success'] == true) {
          final List<dynamic> messages = responseData['data'] is List
              ? responseData['data'] as List
              : [];

          print('📝 Found ${messages.length} messages');
          return messages
              .map(
                (e) => LiveChatMessage.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
        } else {
          throw Exception(
            'API returned success: false. Message: ${responseData['message']}',
          );
        }
      } else {
        // Handle 500 error
        final errorData = response.data is Map
            ? response.data as Map<String, dynamic>
            : {};
        print('❌ Server error details: $errorData');
        throw Exception(
          'Server error: ${errorData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e, stackTrace) {
      print('❌ [LiveChatService] Error fetching messages: $e');
      print('📌 Stack trace: $stackTrace');

      if (e is DioException) {
        print('🌐 Dio error details:');
        print('- Status: ${e.response?.statusCode}');
        print('- Data: ${e.response?.data}');
        print('- Headers: ${e.response?.headers}');
      }

      rethrow;
    }
  }

  Future<LiveChatStatus> fetchStatus(int id) async {
    ApiClient.I.ensureInterceptors();
    final res = await _dio.get('/live-chat/$id/status');
    final body = Map<String, dynamic>.from(res.data);
    return LiveChatStatus.fromJson(
      Map<String, dynamic>.from(body['data'] ?? {}),
    );
  }

  Future<LiveChatMessage> sendMessage(int id, String text) async {
    ApiClient.I.ensureInterceptors();
    final res = await _dio.post(
      '/admin/live-chat/$id/send',
      data: {'message': text},
    );
    final body = Map<String, dynamic>.from(res.data);
    return LiveChatMessage.fromJson(
      Map<String, dynamic>.from(body['data'] ?? {}),
    );
  }

  Future<Map<String, dynamic>> toggleLike(int id) async {
    ApiClient.I.ensureInterceptors();
    final res = await _dio.post('/live-chat/$id/like-toggle');
    final data = Map<String, dynamic>.from(res.data);
    return {
      'liked': data['liked'] == true,
      'likes': data['likes'] is int
          ? data['likes']
          : int.tryParse(data['likes']?.toString() ?? '') ?? 0,
    };
  }

  Future<Map<String, dynamic>> joinListener(int roomId) async {
    ApiClient.I.ensureInterceptors();
    final res = await _dio.post(
      '/live-chat/listener/join',
      data: {'room_id': roomId},
    );
    final body = Map<String, dynamic>.from(res.data);
    return {
      'listenerId': body['listener_id'],
      'listenerCount': body['listener_count'] ?? 0,
    };
  }

  Future<int> leaveListener(int listenerId) async {
    ApiClient.I.ensureInterceptors();
    final res = await _dio.post('/live-chat/listener/$listenerId/leave');
    final body = Map<String, dynamic>.from(res.data);
    return body['listener_count'] is int
        ? body['listener_count']
        : int.tryParse(body['listener_count']?.toString() ?? '') ?? 0;
  }
}
