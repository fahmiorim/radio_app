import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../config/api_client.dart';
import '../config/pusher_config.dart';
import '../models/live_message_model.dart';

// Alias for developer.log
void _log(String message, {String name = 'LiveChatSocketService'}) {
  if (kDebugMode) {
    developer.log(message, name: name);
  } else {
    // In release mode, you might want to use a different logging mechanism
    // or disable logging completely
    debugPrint('[$name] $message');
  }
}

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
  final Set<String> _subscribedChannels = {};

  Future<void> connect() async {
    if (_connected) {
      _log('ℹ️ WebSocket already connected');
      return;
    }

    try {
      _log('🔄 Initializing WebSocket connection...');
      ApiClient.I.ensureInterceptors();
      _subscribedChannels.clear();

      await _pusher.init(
        apiKey: PusherConfig.appKey,
        cluster: PusherConfig.cluster,
        useTLS: true,
        onAuthorizer: (channelName, socketId, options) async {
          try {
            _log('🔑 Authorizing channel: $channelName');
            _log('🔗 Auth endpoint: ${PusherConfig.authEndpoint}');
            _log('🔑 Socket ID: $socketId');
            
            final response = await ApiClient.I.dio.post(
              PusherConfig.authEndpoint,
              data: {
                'channel_name': channelName,
                'socket_id': socketId,
              },
              options: Options(
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
                validateStatus: (status) => status! < 500, // Don't throw for 4xx errors
              ),
            );

            _log('🔑 Auth response status: ${response.statusCode}');
            _log('🔑 Auth response headers: ${response.headers}');
            _log('🔑 Auth response data: ${response.data}');

            if (response.statusCode != 200) {
              throw Exception('Authorization failed with status ${response.statusCode}: ${response.data}');
            }

            if (response.data == null) {
              throw Exception('Empty authorization response');
            }

            _log('✅ Channel $channelName authorized successfully');
            return response.data;
          } catch (e) {
            _log('❌ Authorization failed for $channelName: $e');
            if (e is DioException) {
              _log('❌ Dio error details:');
              _log('  - Response data: ${e.response?.data}');
              _log('  - Status code: ${e.response?.statusCode}');
              _log('  - Headers: ${e.response?.headers}');
              _log('  - Request: ${e.requestOptions.method} ${e.requestOptions.path}');
            }
            rethrow;
          }
        },
        onError: (String message, int? code, dynamic e) {
          _connected = false;
          _log('WebSocket error: $message');
          if (code != null) _log('Error code: $code');
          if (e != null) _log('Error details: $e');
        },
        onConnectionStateChange: (String current, String previous) async {
          _log('Connection state changed from $previous to $current');
          _connected = current == 'CONNECTION_STATE_CONNECTED';
          
          if (current == 'CONNECTION_STATE_DISCONNECTED') {
            _log('Attempting to reconnect...');
            try {
              await _pusher.connect();
            } catch (e) {
              _log('Reconnection failed: $e');
            }
          }
        },
        onEvent: (event) {
          _log('Event received: ${event.eventName}');
        },
        onSubscriptionSucceeded: (String channelName, dynamic data) {
          _log('✅ Subscribed to $channelName');
          _subscribedChannels.add(channelName);
        },
        onSubscriptionError: (String message, dynamic e) {
          _log('❌ Subscription error: $message');
          if (e != null) _log('Subscription error details: $e');
        },
      );

      _log('🔄 Connecting to WebSocket...');
      await _pusher.connect();
      _connected = true;
      _log('✅ WebSocket connected successfully');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (!_connected) {
      _log('ℹ️ WebSocket not connected, skipping disconnect');
      return;
    }

    _log('🔌 Disconnecting WebSocket...');
    try {
      // Create a copy of the list to avoid concurrent modification
      final channelsToUnsubscribe = List<String>.from(_subscribedChannels);
      
      for (final channel in channelsToUnsubscribe) {
        try {
          _log('Unsubscribing from $channel...');
          await _pusher.unsubscribe(channelName: channel);
          _subscribedChannels.remove(channel);
        } catch (e) {
          _log('❌ Error unsubscribing from $channel: $e');
        }
      }

      await _pusher.disconnect();
      _connected = false;
      _log('✅ WebSocket disconnected successfully');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkLiveStatus() async {
    try {
      final response = await ApiClient.I.dioRoot.get('/api/mobile/live/status');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final data = responseData['data'] as Map<String, dynamic>?;

        if (data == null) {
          return _defaultStatus();
        }

        final isLive = data['is_live'] == true;
        return {
          'isLive': isLive,
          'status': isLive ? 'live' : 'stopped',
          'program': data['program'],
          'liveRoom': data['live_room'],
        };
      }
      return _defaultStatus();
    } catch (e) {
      return _defaultStatus();
    }
  }

  Future<List<Map<String, dynamic>>> fetchChatHistory({
    required int roomId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await ApiClient.I.dioRoot.get(
        '/live-chat/$roomId/fetch',
        queryParameters: {'page': page, 'per_page': perPage},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> _defaultStatus() {
    return {
      'isLive': false,
      'status': 'stopped',
      'program': null,
      'liveRoom': null,
    };
  }

  Future<void> subscribePresence({
    required int roomId,
    required void Function(List<Map<String, dynamic>> users) onHere,
    required void Function(Map<String, dynamic> user) onJoining,
    required void Function(Map<String, dynamic> user) onLeaving,
  }) async {
    try {
      await _pusher.subscribe(
        channelName: 'presence-chat.room.$roomId',
        onSubscriptionSucceeded: (data) {
          try {
            final users = <Map<String, dynamic>>[];

            if (data is Map) {
              final presence = _asMap(data['presence']);
              final hash = _asMap(presence['hash']);
              if (hash.isNotEmpty) {
                for (final entry in hash.entries) {
                  final info = _asMap(entry.value);
                  users.add({'id': _intOrString(entry.key), ...info});
                }
              } else if (data['members'] is List) {
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
          } catch (e) {
            rethrow;
          }
        },
        onMemberAdded: (member) {
          try {
            final info = _asMap(member.userInfo);
            onJoining({'id': _intOrString(member.userId), ...info});
          } catch (e) {
            rethrow;
          }
        },
        onMemberRemoved: (member) {
          try {
            final info = _asMap(member.userInfo);
            onLeaving({'id': _intOrString(member.userId), ...info});
          } catch (e) {
            rethrow;
          }
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> subscribePublic({
    required int roomId,
    required void Function(LiveChatMessage message) onMessage,
    required void Function(Map<String, dynamic> data) onSystem,
  }) async {
    try {
      await _pusher.subscribe(
        channelName: 'chat.room.$roomId',
        onEvent: (event) {
          try {
            final payload = _eventMap(event.data);
            if (event.eventName == 'message.sent') {
              final msgMap = _asMap(payload['message']).isNotEmpty
                  ? _asMap(payload['message'])
                  : payload;
              onMessage(LiveChatMessage.fromJson(msgMap));
            } else {
              onSystem(payload);
            }
          } catch (e) {
            rethrow;
          }
        },
      );
    } catch (e) {
      rethrow;
    }
  }

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

  Future<void> subscribeStatus({
    required void Function(int roomId, String status) onUpdated,
  }) async {
    const channelName = 'live-room-status';

    if (!_connected) {
      await connect();
    }

    if (_subscribedChannels.contains(channelName)) {
      return;
    }

    try {
      await _pusher.subscribe(
        channelName: channelName,
        onEvent: (event) {
          if (event.eventName != 'LiveRoomStatusUpdated') {
            return;
          }

          try {
            final payload = _eventMap(event.data);

            final id = _toInt(payload['liveRoomId']);
            final status = (payload['status'] ?? '').toString();

            onUpdated(id, status);
          } catch (e) {
            rethrow;
          }
        },
      );
      _subscribedChannels.add(channelName);
    } catch (e) {
      rethrow;
    }
  }

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
    const channelName = 'live-room-status';
    if (!_subscribedChannels.contains(channelName)) return;

    await _pusher.unsubscribe(channelName: channelName);
    _subscribedChannels.remove(channelName);
  }

  Map<String, dynamic> _eventMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        return Map<String, dynamic>.from(jsonDecode(raw));
      } catch (e) {
        rethrow;
      }
    }
    return {};
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  dynamic _intOrString(dynamic v) {
    if (v == null) return null;
    final n = int.tryParse(v.toString());
    return n ?? v;
  }

  /// Sends a chat message to the specified room
  /// 
  /// [roomId] The ID of the room to send the message to
  /// [message] The message text to send
  /// [onSuccess] Callback when the message is successfully sent
  /// [onError] Callback when there's an error sending the message
  Future<void> sendMessage({
    required int roomId,
    required String message,
    required Function(LiveChatMessage) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // First, send the message to the server
      final response = await ApiClient.I.dioRoot.post(
        '/live-chat/$roomId/send',
        data: {'message': message},
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true) {
          final messageData = responseData['data'] as Map<String, dynamic>;
          final sentMessage = LiveChatMessage.fromJson(messageData);
          onSuccess(sentMessage);
          return;
        }
      }
      
      // If we get here, there was an error
      onError(response.data?['message']?.toString() ?? 'Failed to send message');
    } catch (e) {
      onError(e.toString());
    }
  }
}
