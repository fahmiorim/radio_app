import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../config/api_client.dart';
import '../config/pusher_config.dart';

class LiveChatSocketService {
  LiveChatSocketService._();
  static final LiveChatSocketService I = LiveChatSocketService._();

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  bool _connected = false;
  bool _isConnecting = false;

  bool get isConnected => _connected;

  // Track subscriptions (Dart-side mirror of native)
  final Map<String, bool> _subscribedChannels = {}; // public + status + like
  final Map<String, bool> _presenceChannels = {};

  // Callbacks
  Function(String, Map<String, dynamic>)? _onUserJoined;
  Function(String, Map<String, dynamic>)? _onUserLeft;
  Function(String, Map<String, dynamic>)? _onMessage;
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

  // ===== Connection =====

  Future<void> ensureConnected() async {
    if (_connected) return;
    if (_isConnecting) {
      // tunggu connect yang sedang berlangsung
      while (_isConnecting) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }
    await connect();
  }

  Future<void> connect() async {
    if (_connected || _isConnecting) return;
    _isConnecting = true;
    try {
      await _initializePusher();
      await _pusher.connect();
      // onConnectionStateChange juga akan set _connected,
      // tapi set guard di sini supaya cepat aman.
      _connected = true;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> disconnect() async {
    if (!_connected) return;
    await dispose();
  }

  Future<void> dispose() async {
    try {
      // Unsubscribe semua channel yang kita ketahui (idempotent)
      final channels = <String>{
        ..._subscribedChannels.keys,
        ..._presenceChannels.keys,
      };
      for (final ch in channels) {
        try {
          await _pusher.unsubscribe(channelName: ch);
        } catch (e) {
          debugPrint('Unsubscribe error ($ch): $e');
        }
      }

      _subscribedChannels.clear();
      _presenceChannels.clear();

      if (_connected) {
        await _pusher.disconnect();
        _connected = false;
      }
      // IMPORTANT: jangan re-init di sini. Biarkan connect() yang meng-init lagi saat dibutuhkan.
    } catch (e) {
      debugPrint('Error during dispose: $e');
    }
  }

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
        onError: (String message, int? code, dynamic e) {
          _onSystem?.call({'type': 'error', 'message': message, 'code': code});
        },
        onEvent: (event) {
          try {
            final payload = _eventMap(event.data);

            if (event.channelName == 'live-room-status' &&
                event.eventName == 'LiveRoomStatusUpdated') {
              _onStatusUpdate?.call(payload);
              return;
            }

            if (event.eventName == 'message.sent' ||
                event.eventName.startsWith('client-')) {
              _handleMessageSent(event.channelName, payload);
              return;
            }

            if (event.eventName == 'user.joined' ||
                event.eventName == 'user.left') {
              _handlePresenceEvent(event.eventName, event.channelName, payload);
              return;
            }

            if (event.eventName == 'message.deleted') {
              _handleMessageDeleted(event.channelName, payload);
              return;
            }

            _onSystem?.call(payload);
          } catch (_) {
            // swallow
          }
        },
        onDecryptionFailure: (String event, String reason) {
          _onSystem?.call({
            'type': 'decrypt_error',
            'event': event,
            'reason': reason,
          });
        },
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
      ApiClient.I.ensureInterceptors(); // pastikan token dipasang
      if (channelName.startsWith('presence-') ||
          channelName.startsWith('private-')) {
        final response = await ApiClient.I.dioRoot.post<Map<String, dynamic>>(
          PusherConfig.authEndpoint,
          data: {'socket_id': socketId, 'channel_name': channelName},
        );
        if ((response.statusCode ?? 0) >= 200 &&
            (response.statusCode ?? 0) < 300) {
          return response.data ?? {};
        }
        throw Exception('Auth failed: ${response.statusMessage}');
      }
      return {};
    } catch (e) {
      rethrow;
    }
  }

  // ===== Subscriptions =====

  bool _isAlreadySubscribedError(Object e) {
    final s = e.toString();
    return s.contains('Already subscribed to a channel with name');
  }

  Future<void> subscribeToStatus() async {
    const channelName = 'live-room-status';
    if (_subscribedChannels[channelName] == true) return;

    try {
      await _pusher.subscribe(channelName: channelName);
      _subscribedChannels[channelName] = true;
    } catch (e) {
      if (_isAlreadySubscribedError(e)) {
        // Native sudah subscribed; sinkronkan state Dart dan lanjut
        _subscribedChannels[channelName] = true;
        return;
      }
      rethrow;
    }
  }

  Future<void> subscribeToChat(int roomId) async {
    final channelName = 'chat.room.$roomId';
    if (_subscribedChannels[channelName] == true) return;

    try {
      await _pusher.subscribe(channelName: channelName);
      _subscribedChannels[channelName] = true;
    } catch (e) {
      if (_isAlreadySubscribedError(e)) {
        _subscribedChannels[channelName] = true;
        return;
      }
      rethrow;
    }
  }

  Future<void> subscribeToPresence(int roomId) async {
    final channelName = 'presence-chat.room.$roomId';
    if (_presenceChannels[channelName] == true) return;

    try {
      await _pusher.subscribe(channelName: channelName);
      _presenceChannels[channelName] = true;
    } catch (e) {
      if (_isAlreadySubscribedError(e)) {
        _presenceChannels[channelName] = true;
        return;
      }
      rethrow;
    }
  }

  Future<void> subscribeLike({
    required int roomId,
    required void Function(int likeCount) onUpdated,
  }) async {
    final channelName = 'like-room-$roomId';
    try {
      await _pusher.subscribe(
        channelName: channelName,
        onEvent: (event) {
          if (event.eventName != 'LikeUpdated') return;
          final payload = _eventMap(event.data);
          final count = _toInt(payload['likeCount']);
          onUpdated(count);
        },
      );
      _subscribedChannels[channelName] = true;
    } catch (e) {
      if (_isAlreadySubscribedError(e)) {
        _subscribedChannels[channelName] = true;
        return;
      }
      rethrow;
    }
  }

  Future<void> unsubscribeStatus() async {
    const channelName = 'live-room-status';
    if (_subscribedChannels.remove(channelName) == true) {
      try {
        await _pusher.unsubscribe(channelName: channelName);
      } catch (e) {
        debugPrint('Error unsubscribing status: $e');
      }
    }
  }

  Future<void> unsubscribePublic(int roomId) async {
    final channelName = 'chat.room.$roomId';
    if (_subscribedChannels.remove(channelName) == true) {
      try {
        await _pusher.unsubscribe(channelName: channelName);
      } catch (e) {
        debugPrint('Error unsubscribing public: $e');
      }
    }
  }

  Future<void> unsubscribePresence(int roomId) async {
    final channelName = 'presence-chat.room.$roomId';
    if (_presenceChannels.remove(channelName) == true) {
      try {
        await _pusher.unsubscribe(channelName: channelName);
      } catch (e) {
        debugPrint('Error unsubscribing presence: $e');
      }
    }
  }

  Future<void> unsubscribeLike(int roomId) async {
    final channelName = 'like-room-$roomId';
    if (_subscribedChannels.remove(channelName) == true) {
      try {
        await _pusher.unsubscribe(channelName: channelName);
      } catch (e) {
        debugPrint('Error unsubscribing like: $e');
      }
    }
  }

  // ===== Utils & Handlers =====

  Map<String, dynamic> _eventMap(dynamic raw) {
    try {
      if (raw == null) return {};
      if (raw is Map) return Map<String, dynamic>.from(raw);
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
        if (decoded is List) return {'data': decoded};
      }
    } catch (_) {}
    return {};
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    try {
      if (raw == null) return {};
      if (raw is Map) return Map<String, dynamic>.from(raw);
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
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
    } catch (_) {
      return 0;
    }
  }

  void _handleMessageSent(String channelName, Map<String, dynamic> payload) {
    final Map<String, dynamic> msgMap = payload.containsKey('message')
        ? _asMap(payload['message'])
        : Map<String, dynamic>.from(payload);

    final processedMsg = <String, dynamic>{
      'id': (msgMap['id'] ?? '').toString(),
      'message': msgMap['message']?.toString() ?? '',
      'user_id': (msgMap['user_id'] ?? msgMap['userId'] ?? '').toString(),
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
  }

  void _handlePresenceEvent(
    String eventType,
    String channelName,
    Map<String, dynamic> payload,
  ) {
    try {
      final userData = _asMap(payload['user'] ?? payload['data'] ?? payload);
      final userInfo = _asMap(userData['userInfo'] ?? userData);
      final currentUserId =
          userData['userId']?.toString() ?? userData['id']?.toString();

      if (currentUserId == null || currentUserId.isEmpty) {
        debugPrint('Invalid user data in presence event: $payload');
        return;
      }

      final processedUser = <String, dynamic>{
        'userId': currentUserId,
        'userInfo': {
          'name': userInfo['name']?.toString() ?? 'Unknown User',
          'avatar': userInfo['avatar']?.toString(),
          'email': userInfo['email']?.toString(),
        },
      };

      switch (eventType) {
        case 'user.joined':
          _onUserJoined?.call(channelName, processedUser);
          _onSystem?.call({
            'type': 'system',
            'message':
                '🎉 ${processedUser['userInfo']['name']} telah bergabung ke siaran',
            'user': processedUser,
            'timestamp': DateTime.now().toIso8601String(),
          });
          break;
        case 'user.left':
          _onUserLeft?.call(channelName, processedUser);
          _onSystem?.call({
            'type': 'system',
            'message':
                '👋 ${processedUser['userInfo']['name']} telah meninggalkan siaran',
            'user': processedUser,
            'timestamp': DateTime.now().toIso8601String(),
          });
          break;
        case 'member_added':
          _onUserJoined?.call(channelName, processedUser);
          break;
        case 'member_removed':
          _onUserLeft?.call(channelName, processedUser);
          break;
      }
    } catch (e) {
      debugPrint('Error handling presence event: $e');
    }
  }

  void _handleMessageDeleted(String channelName, Map<String, dynamic> payload) {
    final messageId = payload['message_id']?.toString();
    if (messageId != null) {
      _onMessage?.call('message.deleted', {'id': messageId});
    }
  }
}
