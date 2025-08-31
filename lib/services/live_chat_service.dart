import 'package:dio/dio.dart';

import '../config/api_client.dart';
import '../models/live_chat_message.dart';
import '../models/live_chat_status.dart';

class LiveChatService {
  LiveChatService._();
  static final LiveChatService I = LiveChatService._();

  final Dio _dio = ApiClient.I.dio;

  Future<List<LiveChatMessage>> fetchMessages(int id) async {
    final res = await _dio.get('/live-chat/$id/fetch');
    final body = Map<String, dynamic>.from(res.data);
    if (body['success'] == true && body['data'] is List) {
      final list = List<Map<String, dynamic>>.from(body['data']);
      return list.map(LiveChatMessage.fromJson).toList();
    }
    throw Exception(body['message'] ?? 'Gagal mengambil pesan');
  }

  Future<LiveChatStatus> fetchStatus(int id) async {
    final res = await _dio.get('/live-chat/$id/status');
    final body = Map<String, dynamic>.from(res.data);
    if (body['success'] == true && body['data'] is Map) {
      return LiveChatStatus.fromJson(Map<String, dynamic>.from(body['data']));
    }
    throw Exception(body['message'] ?? 'Gagal mengambil status');
  }

  Future<LiveChatMessage> sendMessage(int id, String text) async {
    final res = await _dio.post('/live-chat/$id/send', data: {'message': text});
    final body = Map<String, dynamic>.from(res.data);
    if (body['success'] == true && body['data'] is Map) {
      return LiveChatMessage.fromJson(Map<String, dynamic>.from(body['data']));
    }
    throw Exception(body['message'] ?? 'Gagal mengirim pesan');
  }

  Future<Map<String, dynamic>> toggleLike(int id) async {
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
    final res = await _dio.post('/live-chat/listener/join', data: {'room_id': roomId});
    final body = Map<String, dynamic>.from(res.data);
    if (body['success'] == true) {
      return {
        'listenerId': body['listener_id'],
        'listenerCount': body['listener_count'] ?? 0,
      };
    }
    throw Exception(body['message'] ?? 'Gagal bergabung');
  }

  Future<int> leaveListener(int listenerId) async {
    final res = await _dio.post('/live-chat/listener/$listenerId/leave');
    final body = Map<String, dynamic>.from(res.data);
    if (body['success'] == true) {
      return body['listener_count'] is int
          ? body['listener_count']
          : int.tryParse(body['listener_count']?.toString() ?? '') ?? 0;
    }
    throw Exception(body['message'] ?? 'Gagal keluar');
  }
}
