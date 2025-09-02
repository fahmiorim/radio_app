import 'dart:async';
import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../config/api_client.dart';
import '../config/pusher_config.dart';

class LiveChatSocketService {
  LiveChatSocketService._();
  static final LiveChatSocketService I = LiveChatSocketService._();

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  bool _connected = false;

  bool get isConnected => _connected;

  Future<void> ensureConnected() async {
    if (!_connected) {
      await connect();
    }
  }

  final Map<String, bool> _subscribedChannels = {};
  final Map<String, bool> _presenceChannels = {};

  // Callbacks
  Function(String, Map<String, dynamic>)? _onUserJoined;
  Function(String, Map<String, dynamic>)? _onUserLeft;
  Function(String, Map<String, dynamic>)? _onMessage; // (channelName, data)
  Function(Map<String, dynamic>)? _onStatusUpdate;
  Function(Map<String, dynamic>)? _onSystem;

  void setCallbacks({
    Function(String, Map<String, dynamic>)? onUserJoined,
    Function(String, Map<String, dynamic>)? onUserLeft,
    Function(String, Map<String, dynamic>)? onMessage,
    Function(Map<String, dynamic>)? onStatusUpdate,
    Function(Map<String, dynamic>)? onSystem,
  }) {
    _onUserJoined = onUserJoined;
    _onUserLeft = onUserLeft;
    _onMessage = onMessage;
    _onStatusUpdate = onStatusUpdate;
    _onSystem = onSystem;
  }

  // ==== Connection lifecycle ====

  Future<void> _initializePusher() async {
    try {
      await _pusher.init(
        apiKey: PusherConfig.appKey,
        cluster: PusherConfig.cluster,
        onConnectionStateChange: (currentState, _) {
          _connected = currentState == 'CONNECTED';
        },
        onAuthorizer: (String channelName, String socketId, dynamic _) async {
          try {
            return await _authenticateChannel(socketId, channelName);
          } catch (e) {
            rethrow;
          }
        },
        onError: (String message, int? code, dynamic e) {},
        // GLOBAL dispatcher untuk SEMUA event
        onEvent: (event) {
          try {
            final payload = _eventMap(event.data);

            // 1) Status live
            if (event.channelName == 'live-room-status' &&
                event.eventName == 'LiveRoomStatusUpdated') {
              _onStatusUpdate?.call(payload);
              return;
            }

            // 2) Pesan chat
            if (event.eventName == 'message.sent' ||
                event.eventName.startsWith('client-')) {
              _handleMessageSent(event.channelName, payload);
              return;
            }

            // 3) Presence custom
            if (event.eventName == 'user.joined' ||
                event.eventName == 'user.left') {
              _handlePresenceEvent(event.eventName, event.channelName, payload);
              return;
            }

            // 4) Hapus pesan
            if (event.eventName == 'message.deleted') {
              _handleMessageDeleted(event.channelName, payload);
              return;
            }

            // 5) Fallback
            _onSystem?.call(payload);
          } catch (e) {
            rethrow;
          }
        },
        onDecryptionFailure: (String event, String reason) {},
        onMemberAdded: (String channel, PusherMember member) {
          _onUserJoined?.call(channel, {
            'userId': member.userId,
            'userInfo': member.userInfo,
          });
        },
        onMemberRemoved: (String channel, PusherMember member) {
          _onUserLeft?.call(channel, {
            'userId': member.userId,
            'userInfo': member.userInfo,
          });
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _authenticateChannel(
    String socketId,
    String channelName,
  ) async {
    try {
      if (channelName.startsWith('presence-') ||
          channelName.startsWith('private-')) {
        final response = await ApiClient.I.dioRoot.post<Map<String, dynamic>>(
          PusherConfig.authEndpoint,
          data: {'socket_id': socketId, 'channel_name': channelName},
        );
        if (response.statusCode == 200) {
          return response.data ?? {};
        }
        throw Exception('Auth failed: ${response.statusMessage}');
      }
      return {};
    } catch (e) {
      rethrow;
    }
  }

  Future<void> connect() async {
    if (_connected) return;
    try {
      _subscribedChannels.clear();
      await _initializePusher();
      await _pusher.connect();
      _connected = true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (!_connected) return;
    await dispose();
  }

  Future<void> dispose() async {
    try {
      // Unsubscribe all
      for (final ch in _subscribedChannels.keys.toList()) {
        await _pusher.unsubscribe(channelName: ch);
      }
      _subscribedChannels.clear();

      for (final ch in _presenceChannels.keys.toList()) {
        await _pusher.unsubscribe(channelName: ch);
      }
      _presenceChannels.clear();

      await _pusher.disconnect();
      _connected = false;
    } catch (e) {
      rethrow;
    }
  }

  // ==== Subscriptions ====

  Future<void> subscribeToPresence(int roomId) async {
    final channelName = 'presence-chat.room.$roomId';
    try {
      if (_presenceChannels[channelName] == true) {
        return;
      }

      final originalOnSubscriptionSucceeded = _pusher.onSubscriptionSucceeded;
      _pusher.onSubscriptionSucceeded = (channel, data) async {
        if (channel == channelName && data is Map) {
          final presenceData = _asMap(data['presence']);
          final hash = _asMap(presenceData['hash']);
          final users = hash.entries.map((entry) {
            final userId = _intOrString(entry.key);
            final user = _asMap(entry.value);
            return {'id': userId, 'userInfo': user};
          }).toList();

          // Kirim pesan sistem bahwa user telah bergabung
          _onSystem?.call({
            'type': 'system',
            'message': '🎉 Anda telah bergabung ke siaran',
            'timestamp': DateTime.now().toIso8601String(),
          });

          // Update daftar user online
          for (final u in users) {
            _onUserJoined?.call(channelName, u);
          }
        }
        originalOnSubscriptionSucceeded?.call(channel, data);
      };

      await _pusher.subscribe(channelName: channelName);
      _presenceChannels[channelName] = true;
    } catch (e) {
      _presenceChannels.remove(channelName);
      rethrow;
    }
  }

  Future<void> subscribeToChat(int roomId) async {
    final channelName = 'chat.room.$roomId';
    try {
      if (_subscribedChannels[channelName] == true) {
        return;
      }
      await _pusher.subscribe(channelName: channelName);
      _subscribedChannels[channelName] = true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> subscribeToStatus() async {
    const channelName = 'live-room-status';
    try {
      if (_subscribedChannels[channelName] == true) {
        return;
      }
      await _pusher.subscribe(channelName: channelName);
      _subscribedChannels[channelName] = true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> subscribeLike({
    required int roomId,
    required void Function(int likeCount) onUpdated,
  }) async {
    final channelName = 'like-room-$roomId';
    await _pusher.subscribe(
      channelName: channelName,
      onEvent: (event) {
        if (event.eventName != 'LikeUpdated') return;
        final payload = _eventMap(event.data);
        final count = _toInt(payload['likeCount']);
        onUpdated(count);
      },
    );
  }

  Future<void> unsubscribePresence(int roomId) async {
    final channelName = 'presence-chat.room.$roomId';
    await _pusher.unsubscribe(channelName: channelName);
    _presenceChannels.remove(channelName);
  }

  Future<void> unsubscribePublic(int roomId) async {
    final channelName = 'chat.room.$roomId';
    await _pusher.unsubscribe(channelName: channelName);
    _subscribedChannels.remove(channelName);
  }

  Future<void> unsubscribeLike(int roomId) async {
    final channelName = 'like-room-$roomId';
    await _pusher.unsubscribe(channelName: channelName);
  }

  Future<void> unsubscribeStatus() async {
    const channelName = 'live-room-status';
    if (_subscribedChannels[channelName] != true) return;
    await _pusher.unsubscribe(channelName: channelName);
    _subscribedChannels.remove(channelName);
  }

  // ==== Utils & event handlers ====

  Map<String, dynamic> _eventMap(dynamic raw) {
    try {
      if (raw == null) return {};
      if (raw is Map) return Map<String, dynamic>.from(raw);
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        } else if (decoded is List) {
          return {'data': decoded};
        }
      }
    } catch (e) {
      rethrow;
    }
    return {};
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    try {
      if (raw == null) return {};
      if (raw is Map) return Map<String, dynamic>.from(raw);
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {
          return {'value': raw};
        }
      }
    } catch (e) {
      rethrow;
    }
    return {};
  }

  int _toInt(dynamic v) {
    try {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is bool) return v ? 1 : 0;
      if (v is String) {
        if (v.isEmpty) return 0;
        final i = int.tryParse(v);
        if (i != null) return i;
        final d = double.tryParse(v);
        if (d != null) return d.toInt();
        final cleaned = v.replaceAll(RegExp(r'[^0-9.-]'), '');
        return int.tryParse(cleaned) ?? 0;
      }
      if (v is num) return v.toInt();
      return _toInt(v.toString());
    } catch (e) {
      return 0;
    }
  }

  dynamic _intOrString(dynamic v) {
    if (v == null) return null;
    try {
      if (v is num) return v;
      if (v is String) {
        if (v.isEmpty) return v;
        final i = int.tryParse(v);
        if (i != null) return i;
        final d = double.tryParse(v);
        if (d != null) return d;
        final s = v.toLowerCase();
        if (s == 'true') return true;
        if (s == 'false') return false;
        return v;
      }
      if (v is bool) return v;
      if (v is Map || v is List) return v;
      return v.toString();
    } catch (e) {
      return v?.toString();
    }
  }

  void _handleMessageSent(String channelName, Map<String, dynamic> payload) {
    try {
      final Map<String, dynamic> msgMap = payload.containsKey('message')
          ? _asMap(payload['message'])
          : Map<String, dynamic>.from(payload);

      final processedMsg = <String, dynamic>{
        'id':
            msgMap['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'message': msgMap['message']?.toString() ?? '',
        'user_id': _toInt(msgMap['user_id'] ?? msgMap['userId']).toString(),
        'name':
            msgMap['name']?.toString() ??
            msgMap['username']?.toString() ??
            'Unknown',
        'avatar': msgMap['avatar']?.toString(),
        'timestamp':
            msgMap['timestamp'] ??
            msgMap['created_at'] ??
            DateTime.now().toIso8601String(),
      };

      _onMessage?.call(channelName, processedMsg);
    } catch (e) {
      rethrow;
    }
  }

  void _handlePresenceEvent(
    String eventType,
    String channelName,
    Map<String, dynamic> payload,
  ) {
    try {
      final userData = _asMap(payload['user'] ?? payload['data'] ?? payload);
      final userInfo = _asMap(userData['userInfo'] ?? userData);

      final processedUser = <String, dynamic>{
        'userId': _toInt(userData['userId'] ?? userData['id']).toString(),
        'userInfo': {
          'name': userInfo['name']?.toString() ?? 'Unknown User',
          'avatar': userInfo['avatar']?.toString(),
          'email': userInfo['email']?.toString(),
        },
      };

      if (eventType == 'user.joined') {
        _onUserJoined?.call(channelName, processedUser);
      } else {
        _onUserLeft?.call(channelName, processedUser);
      }
    } catch (e) {
      rethrow;
    }
  }

  void _handleMessageDeleted(String channelName, Map<String, dynamic> payload) {
    try {
      final messageId = payload['message_id']?.toString();
      if (messageId != null) {
        _onMessage?.call('message.deleted', {'id': messageId});
      }
    } catch (e) {
      rethrow;
    }
  }
}
