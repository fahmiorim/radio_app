import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../config/api_client.dart';
import '../config/pusher_config.dart';
import '../models/live_chat_message.dart';

class LiveChatSocketService {
  LiveChatSocketService._();
  static final LiveChatSocketService I = LiveChatSocketService._();

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  bool _connected = false;

  Future<void> connect() async {
    if (_connected) return;
    ApiClient.I.ensureInterceptors();

    await _pusher.init(
      apiKey: PusherConfig.appKey,
      cluster: PusherConfig.cluster,
      useTLS: true,
      onAuthorizer: (channelName, socketId, options) async {
        final res = await ApiClient.I.dio.post(
          PusherConfig.authEndpoint, // ex: /broadcasting/auth
          data: {
            'channel_name': channelName,
            'socket_id': socketId,
          },
        );
        return res.data; // {auth: "...", channel_data?: "..."}
      },
      onError: (e) => print('Pusher error: ${e.message}'),
      onConnectionStateChange: (c) => print('Pusher: ${c.currentState}'),
    );

    await _pusher.connect();
    _connected = true;
  }

  Future<void> disconnect() async {
    if (!_connected) return;
    await _pusher.disconnect();
    _connected = false;
  }

  // ---------- Presence: presence-chat.room.{id}
  Future<void> subscribePresence({
    required int roomId,
    required void Function(List<Map<String, dynamic>> users) onHere,
    required void Function(Map<String, dynamic> user) onJoining,
    required void Function(Map<String, dynamic> user) onLeaving,
  }) async {
    await _pusher.subscribe(
      channelName: 'presence-chat.room.$roomId',
      onSubscriptionSucceeded: (data) {
        // Bentuk umum dari plugin: { presence: { count, ids, hash: { "<id>": {name:..} } } }
        // Beberapa build custom mungkin { members: [ ... ] }.
        final users = <Map<String, dynamic>>[];

        if (data is Map) {
          // format presence.hash
          final presence = _asMap(data['presence']);
          final hash = _asMap(presence['hash']);
          if (hash.isNotEmpty) {
            for (final entry in hash.entries) {
              final info = _asMap(entry.value);
              users.add({
                'id': _intOrString(entry.key),
                ...info,
              });
            }
          } else if (data['members'] is List) {
            // fallback format members: []
            for (final m in (data['members'] as List)) {
              users.add(_asMap(m));
            }
          }
        } else if (data is List) {
          for (final m in data) {
            users.add(_asMap(m));
          }
        }

        onHere(users);
      },
      onMemberAdded: (member) {
        // member.userId, member.userInfo
        final info = _asMap(member.userInfo);
        onJoining({'id': _intOrString(member.userId), ...info});
      },
      onMemberRemoved: (member) {
        final info = _asMap(member.userInfo);
        onLeaving({'id': _intOrString(member.userId), ...info});
      },
    );
  }

  // ---------- Public chat: chat.room.{id}
  Future<void> subscribePublic({
    required int roomId,
    required void Function(LiveChatMessage message) onMessage,
    required void Function(Map<String, dynamic> data) onSystem,
  }) async {
    await _pusher.subscribe(
      channelName: 'chat.room.$roomId',
      onEvent: (event) {
        final payload = _eventMap(event.data);
        if (event.eventName == 'message.sent') {
          final msgMap = _asMap(payload['message']).isNotEmpty ? _asMap(payload['message']) : payload;
          onMessage(LiveChatMessage.fromJson(msgMap));
        } else {
          onSystem(payload);
        }
      },
    );
  }

  // ---------- Like: like-room-{id}
  Future<void> subscribeLike({
    required int roomId,
    required void Function(int likeCount) onUpdated,
  }) async {
    await _pusher.subscribe(
      channelName: 'like-room-$roomId',
      onEvent: (event) {
        if (event.eventName != 'LikeUpdated') return;
        final payload = _eventMap(event.data);
        final count = _toInt(payload['likeCount']);
        onUpdated(count);
      },
    );
  }

  // ---------- Status global: live-room-status
  Future<void> subscribeStatus({
    required void Function(int roomId, String status) onUpdated,
  }) async {
    await _pusher.subscribe(
      channelName: 'live-room-status',
      onEvent: (event) {
        if (event.eventName != 'LiveRoomStatusUpdated') return;
        final payload = _eventMap(event.data);
        final id = _toInt(payload['liveRoomId']);
        final status = (payload['status'] ?? '').toString();
        onUpdated(id, status);
      },
    );
  }

  // ---------- Unsubscribe helpers (opsional)
  Future<void> unsubscribePresence(int roomId) async {
    await _pusher.unsubscribe(channelName: 'presence-chat.room.$roomId');
  }

  Future<void> unsubscribePublic(int roomId) async {
    await _pusher.unsubscribe(channelName: 'chat.room.$roomId');
  }

  Future<void> unsubscribeLike(int roomId) async {
    await _pusher.unsubscribe(channelName: 'like-room-$roomId');
  }

  Future<void> unsubscribeStatus() async {
    await _pusher.unsubscribe(channelName: 'live-room-status');
  }

  // ---------- Utils
  static Map<String, dynamic> _eventMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try { return Map<String, dynamic>.from(jsonDecode(raw)); } catch (_) {}
    }
    return {};
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
    }

  static dynamic _intOrString(dynamic v) {
    final n = int.tryParse(v?.toString() ?? '');
    return n ?? v;
  }
}
