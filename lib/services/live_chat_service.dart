import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:radio_odan_app/config/api_client.dart';
import 'package:radio_odan_app/models/live_message_model.dart';
import 'package:radio_odan_app/models/live_status_model.dart';
import 'package:radio_odan_app/services/user_service.dart';

class LiveChatService {
  LiveChatService._();
  static final LiveChatService I = LiveChatService._();

  Dio get _dio => ApiClient.I.dioRoot;

  Future<Map<String, String>> _authHeaders() async {
    final token = await UserService.getToken();
    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'X-Requested-With': 'XMLHttpRequest',
    };
  }

  void _ensure() => ApiClient.I.ensureInterceptors();

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString();
    final i = int.tryParse(s);
    if (i != null) return i;
    final d = double.tryParse(s);
    return d?.toInt() ?? 0;
  }

  Future<LiveChatStatus> fetchGlobalStatus({String caller = 'unknown'}) async {
    _ensure();
    final headers = await _authHeaders();
    headers['X-Caller'] = caller; // opsional: jejak siapa pemanggilnya

    final res = await _dio.get<dynamic>(
      '/api/mobile/live/status',
      options: Options(
        headers: headers,
        validateStatus: (s) => s != null && s < 500,
        followRedirects: false,
      ),
    );

    final code = res.statusCode ?? 0;
    final body = _asMap(res.data);

    if (code == 200 && (body['status'] == true || body['success'] == true)) {
      final data = _asMap(body['data']);
      final liveRoom = _asMap(data['live_room']);

      // Get like count from live_room if available
      final count = _toInt(
        liveRoom['like_count'] ?? data['likes'] ?? data['like_count'] ?? 0,
      );

      // Create initial status without liked status
      final roomId = liveRoom['id'] ?? data['room_id'];
      final status = LiveChatStatus.fromJson({
        'is_live': data['is_live'] ?? false,
        'title': liveRoom['judul'] ?? data['title'] ?? '',
        'description': liveRoom['description'] ?? data['description'] ?? '',
        'started_at': liveRoom['started_at'] ?? data['started_at'],
        'likes': count,
        'liked': false, // Will be updated below
        'listener_count': _toInt(data['listener_count'] ?? 0),
        'room_id': roomId,
      });

      // If we have a room ID, try to get the like status from the chat status endpoint
      if (roomId != null) {
        try {
          final chatStatus = await fetchStatus(roomId);
          return status.copyWith(liked: chatStatus.liked);
        } catch (e, s) {
          developer.log(
            'Failed to fetch chat status',
            error: e,
            stackTrace: s,
          );
        }
      }

      return status;
    }
    throw Exception(
      body['message']?.toString() ??
          'Failed to fetch global status (HTTP $code)',
    );
  }

  Future<List<LiveChatMessage>> fetchMessages(
    int roomId, {
    int? page,
    int? perPage,
  }) async {
    try {
      _ensure();
      final headers = await _authHeaders();
      final res = await _dio.get<dynamic>(
        '/api/live-chat/$roomId/fetch',
        queryParameters: {
          if (page != null) 'page': page,
          if (perPage != null) 'per_page': perPage,
        },
        options: Options(
          headers: headers,
          validateStatus: (s) => s != null && s < 500,
          followRedirects: false,
        ),
      );

      final code = res.statusCode ?? 0;
      final body = _asMap(res.data);

      if (code == 200 && body['success'] == true) {
        final list = (body['data'] as List? ?? const []);
        return list
            .map((e) => LiveChatMessage.fromJson(_asMap(e)))
            .toList(growable: false);
      }

      final msg =
          body['message']?.toString() ??
          'Failed to fetch messages (HTTP $code)';
      throw Exception(msg);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Network error fetching messages (HTTP $code): ${data ?? e.message}',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<LiveChatStatus> fetchStatus(int roomId) async {
    try {
      _ensure();
      final headers = await _authHeaders();
      final url = '/api/live-chat/$roomId/status';

      final res = await _dio.get<dynamic>(
        url,
        options: Options(
          headers: headers,
          validateStatus: (s) => s != null && s < 500,
          followRedirects: false,
        ),
      );

      final code = res.statusCode ?? 0;
      final body = _asMap(res.data);

      if (code == 200 && body['success'] == true) {
        final data = _asMap(body['data']);
        return LiveChatStatus.fromJson(data);
      }
      if (code == 401 || code == 403) {
        throw Exception('Unauthorized');
      }
      final msg =
          body['message']?.toString() ?? 'Failed to fetch status (HTTP $code)';
      throw Exception(msg);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Network error fetching status (HTTP $code): ${data ?? e.message}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getOnlineUsers(int roomId) async {
    try {
      _ensure();
      final headers = await _authHeaders();
      final res = await _dio.get<dynamic>(
        '/live-chat/$roomId/status',
        options: Options(
          headers: headers,
          validateStatus: (s) => s != null && s < 500,
          followRedirects: false,
        ),
      );

      final code = res.statusCode ?? 0;
      final body = _asMap(res.data);

      if (code == 200 && body['success'] == true) {
        final data = _asMap(body['data']);
        final users = (data['users'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        return users;
      }

      if (code == 401 || code == 403) {
        throw Exception('Unauthorized');
      }

      final msg =
          body['message']?.toString() ??
          'Failed to fetch online users (HTTP $code)';
      throw Exception(msg);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Network error fetching online users (HTTP $code): ${data ?? e.message}',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<LiveChatMessage> sendMessage(int roomId, String text) async {
    try {
      _ensure();

      final headers = await _authHeaders();
      final res = await _dio.post<dynamic>(
        '/api/live-chat/$roomId/send',
        data: {'message': text},
        options: Options(
          headers: headers,
          validateStatus: (s) => s != null && s < 500,
          followRedirects: false,
        ),
      );

      final code = res.statusCode ?? 0;
      final body = _asMap(res.data);

      if ((code == 200 || code == 201) && body['success'] == true) {
        final data = _asMap(body['data']);
        return LiveChatMessage.fromJson(data);
      }

      if (code == 401 || code == 403) {
        throw Exception('Unauthorized');
      }

      final msg =
          body['message']?.toString() ?? 'Failed to send message (HTTP $code)';
      throw Exception(msg);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Network error sending message (HTTP $code): ${data ?? e.message}',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> toggleLike(int roomId) async {
    try {
      _ensure();
      final headers = await _authHeaders();
      final res = await _dio.post<dynamic>(
        '/api/live-chat/$roomId/like-toggle',
        options: Options(
          headers: headers,
          validateStatus: (s) => s != null && s < 500,
          followRedirects: false,
        ),
      );
      final code = res.statusCode ?? 0;
      final body = _asMap(res.data);
      final src = _asMap(body['data'] ?? body);
      final ok =
          body['success'] == true ||
          body['status'] == true ||
          src.containsKey('liked') ||
          src.containsKey('likes');

      if (code == 200 && ok) {
        return {'liked': src['liked'] == true, 'likes': _toInt(src['likes'])};
      }
      if (code == 401 || code == 403) {
        throw Exception('Unauthorized');
      }
      final msg =
          body['message']?.toString() ?? 'Failed to toggle like (HTTP $code)';
      throw Exception(msg);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Network error toggle like (HTTP $code): ${data ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> joinListener(int roomId) async {
    try {
      _ensure();
      final headers = await _authHeaders();
      final res = await _dio.post<dynamic>(
        '/api/live-chat/listener/join',
        data: {'room_id': roomId},
        options: Options(
          headers: headers,
          validateStatus: (s) => s != null && s < 500,
          followRedirects: false,
        ),
      );
      final code = res.statusCode ?? 0;
      final body = _asMap(res.data);

      if (code == 200 && body['success'] == true) {
        return {
          'listenerId': body['listener_id'],
          'listenerCount': _toInt(body['listener_count']),
        };
      }
      if (code == 401 || code == 403) {
        throw Exception('Unauthorized');
      }
      final msg =
          body['message']?.toString() ?? 'Failed to join listener (HTTP $code)';
      throw Exception(msg);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Network error join listener (HTTP $code): ${data ?? e.message}',
      );
    }
  }

  Future<int> leaveListener(int listenerId) async {
    try {
      _ensure();
      final headers = await _authHeaders();
      final res = await _dio.post<dynamic>(
        '/api/live-chat/listener/$listenerId/leave',
        options: Options(
          headers: headers,
          validateStatus: (s) => s != null && s < 500,
          followRedirects: false,
        ),
      );
      final code = res.statusCode ?? 0;
      final body = _asMap(res.data);

      if (code == 200 && body['success'] == true) {
        return _toInt(body['listener_count']);
      }
      if (code == 401 || code == 403) {
        throw Exception('Unauthorized');
      }
      final msg =
          body['message']?.toString() ??
          'Failed to leave listener (HTTP $code)';
      throw Exception(msg);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'Network error leave listener (HTTP $code): ${data ?? e.message}',
      );
    }
  }
}
