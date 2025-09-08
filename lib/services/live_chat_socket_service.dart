import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  final Map<int, void Function(PusherEvent)> _likeCallbacks = {};

  bool get isConnected => _connected;

  Future<void> ensureConnected() async {
    if (!_connected) {
      await connect();
    }
  }

  final Map<String, bool> _subscribedChannels = {};
  final Map<String, bool> _presenceChannels = {};
  final Map<int, PusherChannel> _likeChannels = {};

  // Get auth token from secure storage
  Future<String?> _getAuthToken() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'user_token');

      if (token == null || token.isEmpty) {
        debugPrint('⚠️ No authentication token found in secure storage');
        return null;
      }

      debugPrint('🔑 Retrieved auth token from secure storage');
      return token;
    } catch (e) {
      debugPrint('❌ Error retrieving auth token: $e');
      return null;
    }
  }

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
      debugPrint(
        'Initializing Pusher with key: ${PusherConfig.appKey} and cluster: ${PusherConfig.cluster}',
      );
      debugPrint('Auth endpoint RESOLVED: ${PusherConfig.authEndpoint}');

      await _pusher.init(
        apiKey: PusherConfig.appKey,
        cluster: PusherConfig.cluster,
        onConnectionStateChange: (currentState, _) {
          debugPrint('Pusher connection state changed: $currentState');
          _connected = currentState == 'CONNECTED';

          // Notify about connection state changes
          _onSystem?.call({
            'type': 'connection_state',
            'state': currentState,
            'timestamp': DateTime.now().toIso8601String(),
          });
        },
        onAuthorizer: (String channelName, String socketId, dynamic _) async {
          try {
            debugPrint(
              'Authorizing channel: $channelName with socket: $socketId',
            );
            final authData = await _authenticateChannel(socketId, channelName);
            debugPrint('Channel $channelName authorized successfully');
            return authData;
          } catch (e) {
            debugPrint('Channel authorization failed for $channelName: $e');
            rethrow;
          }
        },
        onError: (String message, int? code, dynamic e) {
          debugPrint('Pusher error: $message (code: $code)');
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
            debugPrint(
              'Event received - Channel: ${event.channelName}, Event: ${event.eventName}',
            );

            final payload = _eventMap(event.data);
            debugPrint('Event payload: $payload');

            // 1) Status live - handle both formats
            if (event.channelName == 'live-room-status' &&
                (event.eventName.endsWith('.LiveRoomStatusUpdated') ||
                    event.eventName == 'LiveRoomStatusUpdated' ||
                    event.eventName.endsWith('.status.updated') ||
                    event.eventName == 'status.updated')) {
              _onStatusUpdate?.call(payload);
              return;
            }

            // 2) Pesan chat - handle Laravel Echo format (with and without dot prefix)
            if (event.eventName.endsWith('.message.sent') ||
                event.eventName == 'message.sent' ||
                event.eventName.endsWith('message.sent') ||
                event.eventName.startsWith('client-')) {
              // Handle both formats: data.message or direct data
              final messageData = payload['message'] ?? payload;
              _onMessage?.call(event.channelName, _asMap(messageData));
              return;
            }

            // 3) Presence events - handle both formats (with and without dot prefix)
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

            // 4) Hapus pesan - handle both formats
            if (event.eventName.endsWith('.message.deleted') ||
                event.eventName == 'message.deleted') {
              _handleMessageDeleted(event.channelName, payload);
              return;
            }

            // 5) Handle like updates
            if (event.eventName == 'LikeUpdated' ||
                event.eventName.endsWith('LikeUpdated')) {
              final data = _eventMap(event.data);
              final channelName = event.channelName;
              if (channelName.startsWith('like-room-')) {
                final roomId = int.tryParse(
                  channelName.replaceAll('like-room-', ''),
                );
                if (roomId != null) {
                  final likeCount = _toInt(data['likeCount']);
                  debugPrint(
                    '❤️ Global handler: Like count updated to $likeCount for room $roomId',
                  );
                  // This will be handled by the specific subscription in subscribeLike
                }
              }
              return;
            }

            // 6) Fallback for unhandled events
            debugPrint(
              'Unhandled event: ${event.eventName} on ${event.channelName}',
            );
            _onSystem?.call({
              'type': 'unhandled_event',
              'channel': event.channelName,
              'event': event.eventName,
              'data': payload,
              'timestamp': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            debugPrint('Error handling Pusher event: $e');
            _onSystem?.call({
              'type': 'event_error',
              'error': e.toString(),
              'timestamp': DateTime.now().toIso8601String(),
            });
            rethrow;
          }
        },
        onDecryptionFailure: (String event, String reason) {
          final errorMsg =
              'Decryption failed for event: $event, reason: $reason';
          debugPrint(errorMsg);
          _onSystem?.call({
            'type': 'decryption_error',
            'event': event,
            'reason': reason,
            'timestamp': DateTime.now().toIso8601String(),
          });
        },
        onMemberAdded: (String channel, PusherMember member) {
          debugPrint('Member added to $channel: ${member.userId}');
          _onUserJoined?.call(channel, {
            'userId': member.userId,
            'userInfo': member.userInfo,
            'type': 'user_joined',
            'timestamp': DateTime.now().toIso8601String(),
          });
        },
        onMemberRemoved: (String channel, PusherMember member) {
          debugPrint('Member removed from $channel: ${member.userId}');
          _onUserLeft?.call(channel, {
            'userId': member.userId,
            'userInfo': member.userInfo,
            'type': 'user_left',
            'timestamp': DateTime.now().toIso8601String(),
          });
        },
      );

      debugPrint('Pusher initialization completed successfully');
    } catch (e) {
      debugPrint('Failed to initialize Pusher: $e');
      _onSystem?.call({
        'type': 'initialization_error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _authenticateChannel(
    String socketId,
    String channelName,
  ) async {
    try {
      debugPrint('🔐 Authenticating channel: $channelName');

      if (!channelName.startsWith('presence-') &&
          !channelName.startsWith('private-')) {
        debugPrint(
          'No authentication required for public channel: $channelName',
        );
        return {};
      }

      // Get the auth token from your auth service or storage
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Missing auth token');
      }

      debugPrint('🔑 Using token: ***${token.substring(token.length - 5)}');
      debugPrint('➡️  Auth URL: ${PusherConfig.authEndpoint}');

      // IMPORTANT: samakan dengan Postman -> form-encoded (FormData)
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
            // Biarkan Dio yang set Content-Type untuk FormData
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint('🔑 Auth response status: ${response.statusCode}');
      debugPrint('🔑 Auth response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('✅ Channel $channelName authenticated successfully');
        return response.data!;
      }

      final errorMsg =
          '❌ Channel authentication failed: ${response.statusMessage}';
      debugPrint(errorMsg);
      throw Exception(errorMsg);
    } catch (e, stackTrace) {
      debugPrint('❌ Error authenticating channel $channelName');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
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
            return {'userId': userId, 'userInfo': user};
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
      debugPrint('Mencoba subscribe ke channel: $channelName');

      if (_subscribedChannels[channelName] == true) {
        debugPrint('Sudah subscribe ke channel: $channelName');
        return;
      }

      debugPrint('Melakukan subscribe ke channel: $channelName');

      await _pusher.subscribe(
        channelName: channelName,
        onEvent: (event) {
          try {
            debugPrint('=== EVENT DITERIMA ===');
            debugPrint('Channel: $channelName');
            debugPrint('Event Name: ${event.eventName}');
            debugPrint('Raw Data: ${event.data}');

            final data = _eventMap(event.data);
            debugPrint('Parsed Data: $data');

            // Handle event dengan format Laravel Echo (dengan titik di awal)
            if (event.eventName.endsWith('.message.sent') ||
                event.eventName == 'message.sent') {
              debugPrint('Menangani pesan masuk...');
              // Ekstrak data pesan, dukung baik format data.message maupun data langsung
              final messageData = data['message'] ?? data;
              debugPrint('Data pesan yang akan diproses: $messageData');

              if (_onMessage != null) {
                _onMessage!(channelName, _asMap(messageData));
                debugPrint('Pesan berhasil diproses');
              } else {
                debugPrint('PERINGATAN: _onMessage callback belum di-set');
              }
            }
            // Handle event penghapusan pesan
            else if (event.eventName.endsWith('.message.deleted') ||
                event.eventName == 'message.deleted') {
              debugPrint('Menangani penghapusan pesan...');
              _handleMessageDeleted(channelName, data);
            }
            // Handle event lainnya
            else {
              debugPrint('Event tidak dikenali, meneruskan ke handler sistem');
              _onSystem?.call({
                'type': 'system',
                'event': event.eventName,
                'data': data,
                'timestamp': DateTime.now().toIso8601String(),
              });
            }
          } catch (e, stackTrace) {
            debugPrint('Error menangani event:');
            debugPrint('Error: $e');
            debugPrint('Stack trace: $stackTrace');
          } finally {
            debugPrint('=== AKHIR EVENT ===\n');
          }
        },
      );

      _subscribedChannels[channelName] = true;
      debugPrint('✅ Berhasil subscribe ke channel: $channelName');
    } catch (e, stackTrace) {
      _subscribedChannels.remove(channelName);
      debugPrint('❌ Gagal subscribe ke channel $channelName');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
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

  // Track active like subscriptions
  final Map<String, StreamSubscription<dynamic>> _likeSubscriptions = {};

  Future<void> subscribeLike({
    required int roomId,
    required void Function(int likeCount) onUpdated,
  }) async {
    final channelName = 'like-room-$roomId';
    debugPrint('🔔 Subscribing to like updates on channel: $channelName');

    // Pastikan konek
    await ensureConnected();

    // Kalau sudah subscribe sebelumnya, unsubscribe dulu biar gak dobel handler
    try {
      await _pusher.unsubscribe(channelName: channelName);
    } catch (_) {}

    // Subscribe dengan onEvent seperti subscribeToChat
    await _pusher.subscribe(
      channelName: channelName,
      onEvent: (event) {
        try {
          final name = event.eventName ?? '';
          // Terima berbagai kemungkinan nama event
          final isLikeEvent =
              name == 'LikeUpdated' ||
              name.endsWith('.LikeUpdated') ||
              name == 'like-updated';

          if (!isLikeEvent) {
            // biarkan event lain diproses oleh handler global
            return;
          }

          // Parse payload
          final data = _eventMap(event.data);
          // Ambil count dari beberapa kemungkinan key
          final count = _toInt(
            data['likeCount'] ??
                data['like_count'] ??
                (data['data'] is Map ? data['data']['likeCount'] : null) ??
                (data['data'] is Map ? data['data']['like_count'] : null) ??
                0,
          );

          debugPrint('❤️ Like event [$name] on $channelName -> $count');
          onUpdated(count);
        } catch (e) {
          debugPrint('❌ Error in like onEvent: $e');
        }
      },
    );

    // Tandai subscribed (opsional)
    _subscribedChannels[channelName] = true;
    debugPrint(
      '✅ Successfully subscribed to like updates on channel: $channelName',
    );
  }

  Future<void> unsubscribeLike(int roomId) async {
    final channelName = 'like-room-$roomId';
    try {
      await _pusher.unsubscribe(channelName: channelName);
      _subscribedChannels.remove(channelName);
      debugPrint('✅ Unsubscribed from like updates on channel: $channelName');
    } catch (e) {
      debugPrint('⚠️ Error unsubscribing from $channelName: $e');
    }
  }

  void _handleLikeEvent(dynamic eventData, void Function(int) onUpdated) {
    try {
      dynamic data;
      if (eventData is Map) {
        data = eventData;
      } else if (eventData is String) {
        try {
          data = jsonDecode(eventData);
        } catch (e) {
          debugPrint('⚠️ Could not parse event data as JSON: $eventData');
          return;
        }
      }

      if (data != null) {
        debugPrint('✅ Parsed data: $data');

        // Try to extract likeCount from different possible locations
        final count = _toInt(
          data['likeCount'] ??
              (data['data'] is Map ? data['data']['likeCount'] : null) ??
              0,
        );

        debugPrint('❤️ Like count updated: $count');
        onUpdated(count);
      } else {
        debugPrint('⚠️ Received null or invalid like data');
      }
    } catch (e) {
      debugPrint('❌ Error processing like update: $e');
      debugPrint('Stack trace: ${e.toString()}');
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
  }

  Future<void> unsubscribeStatus() async {
    const channelName = 'live-room-status';
    if (_subscribedChannels[channelName] != true) return;
    await _pusher.unsubscribe(channelName: channelName);
    _subscribedChannels.remove(channelName);
  }

  // ...

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
