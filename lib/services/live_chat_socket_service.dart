import 'dart:convert';

import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:radio_odan_app/config/api_client.dart';
import 'package:radio_odan_app/config/pusher_config.dart';

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

  // Like callbacks per-room
  final Map<int, void Function(int)> _likeUpdateCallbacks = {};

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

        // connection state
        onConnectionStateChange: (currentState, _) {
          _connected = currentState == 'CONNECTED';

          _onSystem?.call({
            'type': 'connection_state',
            'state': currentState,
            'timestamp': DateTime.now().toIso8601String(),
          });
        },

        // authorizer (private/presence)
        onAuthorizer: (String channelName, String socketId, dynamic _) async {
          try {
            final authData = await _authenticateChannel(socketId, channelName);
            return authData;
          } catch (_) {}
        },

        // global error
        onError: (String message, int? code, dynamic e) {
          _onSystem?.call({
            'type': 'error',
            'message': message,
            'code': code,
            'timestamp': DateTime.now().toIso8601String(),
          });
        },

        // GLOBAL dispatcher untuk SEMUA event
        onEvent: (event) {
          try {
            // ⬇️ Abaikan event internal Pusher agar log tidak berisik
            if (event.eventName.startsWith('pusher:') ||
                event.eventName.startsWith('pusher_internal:')) {
              if (event.eventName.contains('subscription_succeeded')) {}
              return;
            }

            final payload = _eventMap(event.data);

            // 1) Status live
            if (event.channelName == 'live-room-status' &&
                (event.eventName.endsWith('.LiveRoomStatusUpdated') ||
                    event.eventName == 'LiveRoomStatusUpdated' ||
                    event.eventName.endsWith('.status.updated') ||
                    event.eventName == 'status.updated')) {
              _onStatusUpdate?.call(payload);
              return;
            }

            // 2) Pesan chat
            if (event.eventName.endsWith('.message.sent') ||
                event.eventName == 'message.sent' ||
                event.eventName.endsWith('message.sent') ||
                event.eventName.startsWith('client-')) {
              final messageData =
                  payload['message'] ?? payload; // dukung dua format
              _onMessage?.call(event.channelName, _asMap(messageData));
              return;
            }

            // 3) Presence join/left
            if (event.eventName.endsWith('.user.joined') ||
                event.eventName == 'user.joined') {
              _handlePresenceEvent('user.joined', event.channelName, payload);
              return;
            }
            if (event.eventName.endsWith('.user.left') ||
                event.eventName == 'user.left') {
              _handlePresenceEvent('user.left', event.channelName, payload);
              return;
            }

            // 4) Hapus pesan
            if (event.eventName.endsWith('.message.deleted') ||
                event.eventName == 'message.deleted') {
              _handleMessageDeleted(event.channelName, payload);
              return;
            }

            // 5) LikeUpdated → hanya handler global (hindari double-dispatch)
            if (event.eventName == 'LikeUpdated' ||
                event.eventName.endsWith('LikeUpdated') ||
                event.eventName == 'like-updated' ||
                event.eventName == 'App\\Events\\LikeUpdated') {
              final data = _eventMap(event.data);
              final channelName = event.channelName;

              int? roomId;
              int? likeCount;

              // Room ID: paling tepercaya dari nama channel like-room-{id}
              if (channelName.startsWith('like-room-')) {
                roomId = int.tryParse(
                  channelName.replaceFirst('like-room-', ''),
                );
              }

              // Jika payload menyertakan channel / roomId
              roomId ??= (data['channel'] != null)
                  ? _toInt(
                      data['channel'].toString().replaceAll('like-room-', ''),
                    )
                  : null;
              roomId ??= (data['roomId'] != null)
                  ? _toInt(data['roomId'])
                  : null;
              if (roomId == null && data['data'] is Map) {
                roomId = _toInt(data['data']['roomId']);
              }

              // likeCount: dukung camelCase & snake_case & data nested
              likeCount = _toInt(
                data['likeCount'] ??
                    (data['data'] is Map
                        ? (data['data']['likeCount'] ??
                              data['data']['likes'] ??
                              data['data']['like_count'])
                        : null) ??
                    data['likes'] ??
                    data['like_count'] ??
                    0,
              );

              if (roomId != null) {
                _handleLikeUpdate(roomId, likeCount);
              } else {
                // fallback: coba ambil dari nama channel jika memungkinkan
                if (channelName.startsWith('like-room-')) {
                  final fallbackRoomId = int.tryParse(
                    channelName.replaceFirst('like-room-', ''),
                  );
                  if (fallbackRoomId != null) {
                    _handleLikeUpdate(fallbackRoomId, likeCount);
                  }
                }
              }
              return;
            }

            _onSystem?.call({
              'type': 'unhandled_event',
              'channel': event.channelName,
              'event': event.eventName,
              'data': payload,
              'timestamp': DateTime.now().toIso8601String(),
            });
          } catch (_) {}
        },

        // decrypt error (jika pakai encrypted/private-encrypted)
        onDecryptionFailure: (String event, String reason) {
          _onSystem?.call({
            'type': 'decryption_error',
            'event': event,
            'reason': reason,
            'timestamp': DateTime.now().toIso8601String(),
          });
        },

        // presence add/remove
        onMemberAdded: (String channel, PusherMember member) {
          _onUserJoined?.call(channel, {
            'userId': member.userId,
            'userInfo': member.userInfo,
            'type': 'user_joined',
            'timestamp': DateTime.now().toIso8601String(),
          });
        },
        onMemberRemoved: (String channel, PusherMember member) {
          _onUserLeft?.call(channel, {
            'userId': member.userId,
            'userInfo': member.userInfo,
            'type': 'user_left',
            'timestamp': DateTime.now().toIso8601String(),
          });
        },
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _authenticateChannel(
    String socketId,
    String channelName,
  ) async {
    try {
      if (!channelName.startsWith('presence-') &&
          !channelName.startsWith('private-')) {
        return {};
      }

      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Missing auth token');
      }

      final response = await ApiClient.I.dioRoot.post<Map<String, dynamic>>(
        PusherConfig.authEndpoint,
        data: FormData.fromMap({
          'socket_id': socketId,
          'channel_name': channelName,
        }),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      }

      throw Exception('Channel authentication failed');
    } catch (_) {
      throw Exception('Error authenticating channel $channelName');
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'user_token');
      if (token == null || token.isEmpty) {
        return null;
      }
      return token;
    } catch (_) {
      return null;
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
      if (_presenceChannels[channelName] == true) return;

      final originalOnSubscriptionSucceeded = _pusher.onSubscriptionSucceeded;
      _pusher.onSubscriptionSucceeded = (channel, data) async {
        if (channel == channelName && data is Map) {
          final presenceData = _asMap(data['presence']);
          final hash = _asMap(presenceData['hash']);
          final users = hash.entries.map((entry) {
            final userId = _intOrString(entry.key);
            final user = _asMap(entry.value);
            return {'userId': userId, 'userInfo': user};
          }).toList();

          // Kirim data user yang sedang online ke provider
          // Provider yang akan menangani notifikasi
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
      if (_subscribedChannels[channelName] == true) return;

      await _pusher.subscribe(
        channelName: channelName,
        onEvent: (event) {
          try {
            // Filter internal pusher event di sini juga
            if (event.eventName.startsWith('pusher:') ||
                event.eventName.startsWith('pusher_internal:')) {
              return;
            }

            final data = _eventMap(event.data);

            if (event.eventName.endsWith('.message.sent') ||
                event.eventName == 'message.sent') {
              final messageData = data['message'] ?? data;
              _onMessage?.call(channelName, _asMap(messageData));
            } else if (event.eventName.endsWith('.message.deleted') ||
                event.eventName == 'message.deleted') {
              _handleMessageDeleted(channelName, data);
            } else {
              _onSystem?.call({
                'type': 'system',
                'event': event.eventName,
                'data': data,
                'timestamp': DateTime.now().toIso8601String(),
              });
            }
          } catch (_) {}
        },
      );

      _subscribedChannels[channelName] = true;
    } catch (_) {
      _subscribedChannels.remove(channelName);
      rethrow;
    }
  }

  Future<void> subscribeToStatus() async {
    const channelName = 'live-room-status';
    try {
      if (_subscribedChannels[channelName] == true) return;
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

    _likeUpdateCallbacks[roomId] = onUpdated;

    await ensureConnected();

    if (_subscribedChannels[channelName] == true) return;

    try {
      await _pusher.subscribe(channelName: channelName);
      _subscribedChannels[channelName] = true;
    } catch (_) {
      _subscribedChannels.remove(channelName);
      rethrow;
    }
  }

  Future<void> unsubscribeLike(int roomId) async {
    final channelName = 'like-room-$roomId';
    try {
      _likeUpdateCallbacks.remove(roomId);
      await _pusher.unsubscribe(channelName: channelName);
      _subscribedChannels.remove(channelName);
    } catch (_) {
      _likeUpdateCallbacks.remove(roomId);
    }
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

  Future<void> unsubscribeStatus() async {
    const channelName = 'live-room-status';
    if (_subscribedChannels[channelName] != true) return;
    await _pusher.unsubscribe(channelName: channelName);
    _subscribedChannels.remove(channelName);
  }

  // ==== Utilities ====

  // Dispatch like update ke callback yang terdaftar
  void _handleLikeUpdate(int roomId, int count) {
    final cb = _likeUpdateCallbacks[roomId];
    if (cb != null) {
      cb(count);
      return;
    }
    // fallback pencocokan string
    final match = _likeUpdateCallbacks.keys.firstWhere(
      (id) => id.toString() == roomId.toString(),
      orElse: () => -1,
    );
    if (match != -1) {
      _likeUpdateCallbacks[match]?.call(count);
    } else {
      final channelName = 'like-room-$roomId';
      if (_subscribedChannels.containsKey(channelName)) {}
    }
  }

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
    } catch (_) {}
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
    } catch (_) {
      return v?.toString();
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

      final uid = _toInt(userData['userId'] ?? userData['id']);
      final processedUser = <String, dynamic>{
        'userId': uid > 0 ? uid.toString() : '',
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
    } catch (_) {}
  }

  void _handleMessageDeleted(String channelName, Map<String, dynamic> payload) {
    try {
      final messageId = payload['message_id']?.toString();
      if (messageId != null) {
        _onMessage?.call('message.deleted', {'id': messageId});
      }
    } catch (_) {}
  }
}
