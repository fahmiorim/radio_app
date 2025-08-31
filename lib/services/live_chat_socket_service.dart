import 'dart:convert';
import 'dart:async';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:dio/dio.dart' show Options;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:radio_odan_app/services/user_service.dart';
import '../config/pusher_config.dart';
import '../models/live_message_model.dart';
import '../config/api_client.dart';

// Alias for developer.log
void _log(String message, {String name = 'LiveChatSocketService'}) {}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized']);
  @override
  String toString() => message;
}

class LiveChatSocketService {
  LiveChatSocketService._();
  static final LiveChatSocketService I = LiveChatSocketService._();

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  bool _connected = false;
  
  // Handle Pusher authentication
  Future<Map<String, dynamic>> _authenticateChannel(String socketId, String channelName) async {
    try {
      // For presence channels, we need to get the auth token from the server
      if (channelName.startsWith('presence-') || channelName.startsWith('private-')) {
        final response = await ApiClient.I.dioRoot.post<Map<String, dynamic>>(
          PusherConfig.authEndpoint,
          data: {
            'socket_id': socketId,
            'channel_name': channelName,
          },
        );
        
        if (response.statusCode == 200) {
          return response.data ?? {};
        } else {
          throw Exception('Failed to authenticate: ${response.statusMessage}');
        }
      }
      
      // For public channels, we don't need authentication
      return {};
    } catch (e) {
      _log('❌ Error authenticating channel $channelName: $e');
      rethrow;
    }
  }

  bool get isConnected => _connected;

  Future<void> ensureConnected() async {
    if (!_connected) {
      await connect();
    }
  }

  final Map<String, dynamic> _subscribedChannels = {};
  final Map<String, dynamic> _presenceChannels = {};

  // Callbacks
  Function(String, Map<String, dynamic>)? _onUserJoined;
  Function(String, Map<String, dynamic>)? _onUserLeft;
  Function(String, Map<String, dynamic>)? _onMessage;
  Function(Map<String, dynamic>)? _onStatusUpdate;
  Function(String, Map<String, dynamic>)? _onMessageReceived;
  Function(Map<String, dynamic>)? _onStatusUpdated;
  Function(Map<String, dynamic>)? _onSystem;

  // Set callbacks for various events
  void setCallbacks({
    Function(String, Map<String, dynamic>)? onUserJoined,
    Function(String, Map<String, dynamic>)? onUserLeft,
    Function(String, Map<String, dynamic>)? onMessage,
    Function(Map<String, dynamic>)? onStatusUpdate,
    Function(String, Map<String, dynamic>)? onMessageReceived,
    Function(Map<String, dynamic>)? onStatusUpdated,
    Function(Map<String, dynamic>)? onSystem,
  }) {
    _onUserJoined = onUserJoined;
    _onUserLeft = onUserLeft;
    _onMessage = onMessage;
    _onStatusUpdate = onStatusUpdate;
    _onMessageReceived = onMessageReceived;
    _onStatusUpdated = onStatusUpdated;
    _onSystem = onSystem;
  }

  // Initialize Pusher connection
  Future<void> _initializePusher() async {
    try {
      _log('🚀 Initializing Pusher...');
      _log('📡 Pusher Config - Key: ${PusherConfig.appKey}');
      _log('📡 Pusher Config - Cluster: ${PusherConfig.cluster}');
      _log('📡 Pusher Auth Endpoint: ${PusherConfig.authEndpoint}');
      
      // Initialize Pusher with your credentials
      await _pusher.init(
        apiKey: PusherConfig.appKey,
        cluster: PusherConfig.cluster,
        onConnectionStateChange: (currentState, _) {
          _log('🔄 Connection state changed: $currentState');
          _connected = currentState == 'CONNECTED';
          if (_connected) {
            _log('✅ Pusher connected successfully');
            _log('📡 Socket ID: ${_pusher.getSocketId()}');
          } else {
            _log('⚠️ Pusher disconnected or connecting');
          }
        },
        onAuthorizer: (String channelName, String socketId, dynamic options) async {
          _log('🔑 Authorizing channel: $channelName');
          try {
            final authData = await _authenticateChannel(socketId, channelName);
            _log('✅ Channel authorized: $channelName');
            return authData;
          } catch (e) {
            _log('❌ Channel authorization failed: $e');
            rethrow;
          }
        },
        onError: (String message, int? code, dynamic e) {
          try {
            _log(
              '❌ Pusher error: $message (code: $code, error: $e)',
              name: 'PusherError',
            );
            _log('❌ Pusher auth error: $e');
          } catch (e) {
            _log('❌ Error in Pusher error handler: $e');
            rethrow;
          }
        } as dynamic Function(String, int?, dynamic)?,
        onEvent: (event) {
          _log('📨 Event received: ${event.eventName}');
          try {
            final dynamic decodedData = event.data != null ? jsonDecode(event.data!) : {};
            
            // Handle different event types
            if (event.eventName == 'message.sent' || event.eventName.startsWith('client-')) {
              // For chat messages
              Map<String, dynamic> messageData = {};
              
              if (decodedData is Map<String, dynamic>) {
                messageData = decodedData;
                // If there's a nested message object, use that
                if (messageData.containsKey('message') && messageData['message'] is Map) {
                  messageData = Map<String, dynamic>.from(messageData['message']);
                }
              } else {
                messageData = {'message': decodedData.toString()};
              }
              
              // Ensure required fields exist
              messageData['id'] = messageData['id'] ?? '${DateTime.now().millisecondsSinceEpoch}';
              messageData['name'] = messageData['name'] ?? messageData['username'] ?? 'User';
              messageData['message'] = messageData['message']?.toString() ?? '';
              messageData['timestamp'] = messageData['timestamp'] ?? DateTime.now().toIso8601String();
              
              _log('📩 Dispatching message: ${messageData['message']}');
              _onMessageReceived?.call(event.channelName, messageData);
            } else if (event.eventName == 'LiveRoomStatusUpdated') {
              try {
                final statusData = jsonDecode(event.data!);
                _onStatusUpdated?.call(statusData);
              } catch (e) {
                _log('❌ Error processing status update: $e');
              }
            }
          } catch (e) {
            _log('❌ Error processing event: $e');
          }
        },
        onDecryptionFailure: (String event, String reason) {
          _log('🔒 Decryption failed for event $event: $reason');
        },
        onMemberAdded: (String channel, PusherMember member) {
          _log('👤 Member added to $channel: ${member.userId}');
          _onUserJoined?.call(channel, {
            'userId': member.userId,
            'userInfo': member.userInfo,
          });
        },
        onMemberRemoved: (String channel, PusherMember member) {
          _log('👋 Member removed from $channel: ${member.userId}');
          _onUserLeft?.call(channel, {
            'userId': member.userId,
            'userInfo': member.userInfo,
          });
        },
      );

      _log('🚀 Pusher initialized');
      await _pusher.connect();
    } catch (e) {
      _log('❌ Error initializing Pusher: $e');
      rethrow;
    }
  }

  Future<void> connect() async {
    if (_connected) {
      _log('ℹ️ WebSocket already connected');
      return;
    }

    try {
      _log('🔄 Initializing WebSocket connection...');
      _subscribedChannels.clear();

      await _initializePusher();
      await _pusher.connect();
      _connected = true;
      _log('✅ WebSocket connected successfully');
    } catch (e) {
      _log('❌ Error connecting to WebSocket: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (!_connected) return;
    try {
      final channelsToUnsubscribe = _subscribedChannels.keys.toList();

      for (final channel in channelsToUnsubscribe) {
        try {
          _log('Unsubscribing from $channel...');
          await _pusher.unsubscribe(channelName: channel);
          _subscribedChannels.remove(channel);
        } catch (e) {
          _log('❌ Error unsubscribing from $channel: $e');
        }
      }

      // Clean up resources
      await dispose();
    } catch (e) {
      _log('❌ Error during disconnect: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    _log('🧹 Cleaning up WebSocket resources');
    try {
      // Unsubscribe from all channels
      for (final channel in _subscribedChannels.keys.toList()) {
        await _pusher.unsubscribe(channelName: channel);
      }
      _subscribedChannels.clear();

      // Unsubscribe from all presence channels
      for (final channel in _presenceChannels.keys.toList()) {
        await _pusher.unsubscribe(channelName: channel);
      }
      _presenceChannels.clear();

      // Disconnect from Pusher
      await _pusher.disconnect();
      _connected = false;
      _log('✅ WebSocket resources cleaned up');
    } catch (e) {
      _log('❌ Error during cleanup: $e');
      rethrow;
    }
  }

  // Handle presence channel subscription
  Future<void> _handlePresenceSubscription(
    String channelName, {
    required int roomId,
  }) async {
    try {
      _log('👥 Setting up presence channel: $channelName');

      if (_presenceChannels.containsKey(channelName)) {
        _log('ℹ️ Already subscribed to presence channel: $channelName');
        return;
      }

      // Set up member added callback
      _pusher.onMemberAdded = (String channel, PusherMember member) {
        if (channel == channelName) {
          _log('👤 User joined: ${member.userId}');
          _onUserJoined?.call(channel, {
            'userId': member.userId,
            'userInfo': member.userInfo,
            'roomId': roomId,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      };

      // Set up member removed callback
      _pusher.onMemberRemoved = (String channel, PusherMember member) {
        if (channel == channelName) {
          _log('👋 User left: ${member.userId}');
          _onUserLeft?.call(channel, {
            'userId': member.userId,
            'userInfo': member.userInfo,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      };

      _presenceChannels[channelName] = true;
    } catch (e) {
      _log('❌ Error handling presence subscription: $e');
    }
  }

  // Handle status events
  void _handleStatusEvents() {
    try {
      _log('🔄 Setting up status events');

      // Save the original onEvent callback
      final originalOnEvent = _pusher.onEvent;

      _pusher.onEvent = (PusherEvent event) {
        if (event.eventName == 'LiveRoomStatusUpdated') {
          try {
            final statusData = jsonDecode(event.data!);
            _log('🔄 Status updated: ${statusData['is_live']}');
            _onStatusUpdate?.call(statusData);
          } catch (e) {
            _log('❌ Error processing status update: $e');
          }
        }

        // Call the original callback if it exists
        if (originalOnEvent != null) {
          originalOnEvent(event);
        }
      };
    } catch (e) {
      _log('❌ Error setting up status events: $e');
    }
  }

  // Handle chat message events
  void _handleChatEvents(String channelName) {
    try {
      _log('💬 Setting up chat events for channel: $channelName');

      // Save the original onEvent callback
      final originalOnEvent = _pusher.onEvent;

      _pusher.onEvent = (PusherEvent event) {
        if (event.channelName == channelName &&
            event.eventName == 'message.sent') {
          try {
            final messageData = jsonDecode(event.data!);
            _log('📩 Received message: ${messageData['id']}');
            _onMessage?.call(channelName, messageData);
          } catch (e) {
            _log('❌ Error processing message: $e');
          }
        }

        // Call the original callback if it exists
        if (originalOnEvent != null) {
          originalOnEvent(event);
        }
      };

      _subscribedChannels[channelName] = true;
    } catch (e) {
      _log('❌ Error setting up chat events: $e');
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

  Future<void> subscribeToPresence(int roomId) async {
    final channelName = 'chat.room.$roomId';

    try {
      // Check if already subscribed
      if (_presenceChannels.containsKey(channelName) &&
          _presenceChannels[channelName] == true) {
        _log('ℹ️ Already subscribed to presence channel: $channelName');
        return;
      }

      _log('🔔 Subscribing to presence channel: $channelName');

      // Store the original callbacks
      final originalOnSubscriptionSucceeded = _pusher.onSubscriptionSucceeded;

      // Override the subscriptionSucceeded callback temporarily
      _pusher.onSubscriptionSucceeded = (channel, data) async {
        _log('✅ Subscribed to presence channel: $channel');

        // Handle presence data
        if (data != null && data is Map) {
          final presenceData = _asMap(data['presence']);
          if (presenceData.isNotEmpty) {
            final count = _toInt(presenceData['count']);
            final hash = _asMap(presenceData['hash']);
            final me = _asMap(presenceData['me']);

            _log('👥 Presence data - Count: $count, Me: $me');

            // Process all users in the channel
            final users = hash.entries.map((entry) {
              final userId = _intOrString(entry.key);
              final user = _asMap(entry.value);
              return {'id': userId, 'userInfo': user};
            }).toList();

            _log('👥 Initial presence data: ${users.length} users');

            // Notify about users already in the channel
            for (var user in users) {
              _onUserJoined?.call(channelName, user);
            }
          }
        }

        // Call the original callback if it exists
        if (originalOnSubscriptionSucceeded != null) {
          originalOnSubscriptionSucceeded(channel, data);
        }
      };

      // Subscribe to the channel
      await _pusher.subscribe(channelName: channelName);
      _log('✅ Successfully subscribed to presence channel: $channelName');
      _presenceChannels[channelName] = true;
    } catch (e) {
      _log('❌ Error subscribing to presence channel: $e');
      _presenceChannels.remove(
        channelName,
      ); // Remove from tracking if subscription fails
      rethrow;
    }
  }

  Future<void> subscribeToChat(int roomId) async {
    final channelName = 'chat.room.$roomId';
    if (_subscribedChannels[channelName] != null) {
      _log('ℹ️ Already subscribed to chat channel: $channelName');
      return;
    }

    try {
      _log('🔔 Subscribing to chat channel: $channelName');

      // Single subscription with both channel subscription and event handling
      await _pusher.subscribe(
        channelName: channelName,
        onEvent: (event) {
          try {
            _log('📨 Received event on $channelName: ${event.eventName}');

            try {
              // Safely parse the event data
              final payload = _eventMap(event.data);
              _log('📦 Payload: $payload');

              // Handle different event types
              switch (event.eventName) {
                case 'message.sent':
                  _handleMessageSent(channelName, payload);
                  break;
                case 'user.joined':
                case 'user.left':
                  _handlePresenceEvent(event.eventName, channelName, payload);
                  break;
                case 'message.deleted':
                  _handleMessageDeleted(channelName, payload);
                  break;
                default:
                  _log('⚙️ Unhandled event type: ${event.eventName}');
                  _onSystem?.call(payload);
              }
            } catch (e, stackTrace) {
              _log(
                '❌ Error processing event: $e\n$stackTrace',
                name: 'EventProcessingError',
              );
            }
          } catch (e) {
            _log('❌ Error processing chat event: $e');
            rethrow;
          }
        },
      );

      _log('✅ Successfully subscribed to chat channel: $channelName');
      _subscribedChannels[channelName] = true;
    } catch (e) {
      _log('❌ Error subscribing to chat channel $channelName: $e');
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

  Future<void> subscribeToStatus() async {
    const channelName = 'live-room-status';
    if (_subscribedChannels[channelName] != null) {
      _log('ℹ️ Already subscribed to status channel');
      return;
    }

    try {
      _log('🔔 Subscribing to status channel');

      // Save the original onSubscriptionSucceeded callback
      final originalOnSubscriptionSucceeded = _pusher.onSubscriptionSucceeded;

      // Set up subscription succeeded callback
      _pusher.onSubscriptionSucceeded = (String channel, dynamic data) {
        _log('📡 Status subscription succeeded: $channel');

        // Call the original callback if it exists
        if (originalOnSubscriptionSucceeded != null) {
          originalOnSubscriptionSucceeded(channel, data);
        }
      };

      // Subscribe to the channel
      await _pusher.subscribe(channelName: channelName);
      _log('✅ Subscribed to status channel');
      _subscribedChannels[channelName] = true;

      // Set up status event handler
      _handleStatusEvents();
    } catch (e) {
      _log('❌ Error subscribing to status channel: $e');
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
    if (!_subscribedChannels.containsKey(channelName)) return;

    await _pusher.unsubscribe(channelName: channelName);
    _subscribedChannels.remove(channelName);
  }

  /// Safely converts raw event data to a Map<String, dynamic>
  /// Handles null, Map, and JSON string inputs
  Map<String, dynamic> _eventMap(dynamic raw) {
    try {
      if (raw == null) return {};
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          } else if (decoded is List) {
            return {'data': decoded};
          }
        } catch (e) {
          _log('❌ Error decoding JSON: $e');
        }
      }
    } catch (e) {
      _log('❌ Error in _eventMap: $e');
    }
    return {};
  }

  /// Safely converts any value to a Map<String, dynamic>
  /// Returns an empty map if conversion is not possible
  Map<String, dynamic> _asMap(dynamic raw) {
    try {
      if (raw == null) return {};
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          // If it's not JSON, treat it as a string value
          return {'value': raw};
        }
      }
    } catch (e) {
      _log('❌ Error in _asMap: $e');
    }
    return {};
  }

  /// Safely converts any value to an int
  /// Returns 0 if conversion is not possible
  int _toInt(dynamic v) {
    try {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is bool) return v ? 1 : 0;
      if (v is String) {
        if (v.isEmpty) return 0;
        // Try parsing as int first
        final intVal = int.tryParse(v);
        if (intVal != null) return intVal;
        // Then try parsing as double
        final doubleVal = double.tryParse(v);
        if (doubleVal != null) return doubleVal.toInt();
        // Check for boolean strings
        final lowerV = v.toLowerCase();
        if (lowerV == 'true') return 1;
        if (lowerV == 'false') return 0;
        // If it's a number with formatting (e.g., "1,234")
        final cleanStr = v.replaceAll(RegExp(r'[^0-9.-]'), '');
        if (cleanStr.isNotEmpty) {
          return int.tryParse(cleanStr) ?? 0;
        }
        return 0;
      }
      if (v is num) return v.toInt();
      // For any other type, try to convert to string and parse
      try {
        return _toInt(v.toString());
      } catch (_) {
        return 0;
      }
    } catch (e) {
      _log('❌ Error converting to int: $e (value: $v)');
      return 0;
    }
  }

  /// Converts a value to either int, double, bool, or keeps it as is
  /// Returns null for null input
  dynamic _intOrString(dynamic v) {
    if (v == null) return null;
    try {
      // Handle num types
      if (v is num) return v;

      // Handle String
      if (v is String) {
        if (v.isEmpty) return v;

        // Try parsing as int
        final intVal = int.tryParse(v);
        if (intVal != null) return intVal;

        // Try parsing as double
        final doubleVal = double.tryParse(v);
        if (doubleVal != null) return doubleVal;

        // Check for boolean strings
        final lowerV = v.toLowerCase();
        if (lowerV == 'true') return true;
        if (lowerV == 'false') return false;

        // Return original string if no conversion possible
        return v;
      }

      // Handle bool
      if (v is bool) return v;

      // For any other type, try to convert to string and parse
      if (v is Map || v is List) return v;

      // For other types, return string representation
      return v.toString();
    } catch (e) {
      _log('❌ Error in _intOrString: $e (value: $v)');
      return v?.toString();
    }
  }

  /// Handles incoming chat messages
  void _handleMessageSent(String channelName, Map<String, dynamic> payload) {
    try {
      // Handle different message formats
      final Map<String, dynamic> msgMap;

      // Case 1: Message is nested under 'message' key
      if (payload.containsKey('message')) {
        msgMap = _asMap(payload['message']);
      }
      // Case 2: Payload is the message itself
      else {
        msgMap = Map<String, dynamic>.from(payload);
      }

      // Ensure required fields with proper type conversion
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

      _log('💬 Processing message: ${processedMsg['id']}');
      _onMessage?.call('message.sent', processedMsg);
      _onMessageReceived?.call(channelName, processedMsg);
    } catch (e, stackTrace) {
      _log(
        '❌ Error processing message: $e\n$stackTrace',
        name: 'MessageProcessingError',
      );
    }
  }

  /// Handles presence events (user joined/left)
  void _handlePresenceEvent(
    String eventType,
    String channelName,
    Map<String, dynamic> payload,
  ) {
    try {
      _log('👤 $eventType: $payload');

      // Extract user data with null safety
      final userData = _asMap(payload['user'] ?? payload['data'] ?? payload);

      // Process user data with proper type conversion
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
    } catch (e, stackTrace) {
      _log(
        '❌ Error processing $eventType event: $e\n$stackTrace',
        name: 'PresenceEventError',
      );
    }
  }

  /// Handles message deletion events
  void _handleMessageDeleted(String channelName, Map<String, dynamic> payload) {
    try {
      final messageId = payload['message_id']?.toString();
      if (messageId != null) {
        _log('🗑️ Message deleted: $messageId');
        _onMessage?.call('message.deleted', {'id': messageId});
      }
    } catch (e, stackTrace) {
      _log(
        '❌ Error processing message deletion: $e\n$stackTrace',
        name: 'MessageDeletionError',
      );
    }
  }

  /// Sends a chat message to the specified room
  ///
  /// [roomId] The ID of the room to send the message to
  /// Sends a chat message to the specified room
  /// [roomId] The ID of the chat room
  /// [message] The message text to send
  /// [onSuccess] Callback when the message is successfully sent
  /// [onError] Callback when there's an error sending the message
  Future<void> sendMessage({
    required int roomId,
    required String message,
    Function(LiveChatMessage)? onSuccess,
    required Function(String) onError,
    Function()? onUnauthorized,
  }) async {
    try {
      _log('📤 Attempting to send message to room $roomId: $message');

      final currentUser = await _getCurrentUserInfo();

      // Send the message via HTTP
      await _sendMessageViaHttp(
        roomId,
        message,
        currentUser,
        onSuccess,
        onError,
        onUnauthorized,
      );
    } on UnauthorizedException {
      rethrow;
    } catch (e, stackTrace) {
      _log('❌ Error in sendMessage: $e\n$stackTrace', name: 'SendMessageError');
      onError('Failed to send message: ${e.toString()}');
    }
  }
  
  // Fallback method to send message via HTTP
  Future<void> _sendMessageViaHttp(
    int roomId,
    String message,
    Map<String, dynamic> currentUser,
    Function(LiveChatMessage)? onSuccess,
    Function(String) onError,
    Function()? onUnauthorized,
  ) async {
    try {
      _log('🔄 Sending message via HTTP to room $roomId');

      _log('👤 Current user: ${currentUser['id']} - ${currentUser['name']}');
      
      // Get authentication token
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        _log('❌ No authentication token found');
        await UserService.clearToken();
        onError('You need to be logged in to send messages');
        onUnauthorized?.call();
        throw UnauthorizedException('No authentication token');
      }
      
      // Prepare the request data
      final requestData = {
        'message': message,
        'user_id': currentUser['id'],
        'name': currentUser['name'],
        'avatar': currentUser['avatar'],
      };
      
      _log('📤 Sending request to /live-chat/$roomId/send');
      _log('📝 Request data: $requestData');
      
      // Log the headers we're about to send
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'X-Requested-With': 'XMLHttpRequest',
      };
      _log('📋 Request headers: $headers');
      
      // Make the HTTP request with proper headers
      _log('🚀 Sending POST request...');
      final response = await ApiClient.I.dio.post(
        '/live-chat/$roomId/send',
        data: requestData,
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500,
          followRedirects: false,
        ),
      );

      _log('📥 Received response:');
      _log('  Status: ${response.statusCode}');
      _log('  Headers: ${response.headers}');
      _log('  Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true) {
          final messageData = responseData['data'] ?? responseData;
          _log('✅ Message sent successfully');
          
          // Create a LiveChatMessage from the response
          final sentMessage = LiveChatMessage(
            id: messageData['id'] as int? ?? DateTime.now().millisecondsSinceEpoch,
            message: messageData['message']?.toString() ?? message,
            userId: int.tryParse(messageData['user_id']?.toString() ?? '0') ?? 0,
            name: messageData['name']?.toString() ?? currentUser['name'] ?? 'User',
            avatar: messageData['avatar']?.toString() ?? currentUser['avatar'] ?? '',
            timestamp: messageData['created_at'] != null 
                ? DateTime.parse(messageData['created_at'].toString())
                : DateTime.now(),
          );
          
          onSuccess?.call(sentMessage);
          return;
        }
      }
      
      // Handle different error statuses
      String errorMessage = 'Failed to send message';

      if (response.statusCode == 401 || response.statusCode == 403) {
        errorMessage = 'Authentication failed. Please log in again.';
        await UserService.clearToken();
        onUnauthorized?.call();
        onError(errorMessage);
        throw UnauthorizedException(errorMessage);
      } else if (response.statusCode == 422) {
        // Handle validation errors
        if (response.data is Map && response.data['errors'] != null) {
          final errors = response.data['errors'] as Map<String, dynamic>;
          errorMessage = errors.values.first?.first?.toString() ?? errorMessage;
        }
      } else if (response.data is Map && response.data['message'] != null) {
        errorMessage = response.data['message'].toString();
      } else if (response.statusMessage != null) {
        errorMessage = '${response.statusCode}: ${response.statusMessage}';
      }

      _log('❌ Failed to send message: $errorMessage');
      onError(errorMessage);
    } catch (e, stackTrace) {
      _log('❌ HTTP send message failed: $e\n$stackTrace');
      onError('Failed to send message: ${e.toString()}');
    }
  }

  // Get current user info
  Future<Map<String, dynamic>> _getCurrentUserInfo() async {
    try {
      final user = await UserService.getProfile();
      if (user != null) {
        return {
          'id': user.id.toString(),
          'name': user.name,
          'avatar': user.avatarUrl.isNotEmpty ? user.avatarUrl : null,
        };
      }
    } catch (e) {
      _log('❌ Error getting current user info: $e');
    }
    return {
      'id': '',
      'name': 'User',
      'avatar': null,
    };
  }
  
  // Get authentication token from secure storage
  Future<String?> _getAuthToken() async {
    try {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'user_token');
      _log('🔑 Retrieved auth token: ${token != null ? 'Token exists' : 'Token is null'}');
      if (token == null) {
        _log('⚠️ No auth token found in secure storage');
      } else if (token.isEmpty) {
        _log('⚠️ Auth token is empty');
      } else {
        _log('✅ Valid auth token found');
      }
      return token;
    } catch (e) {
      _log('❌ Error getting auth token: $e');
      return null;
    }
  }

}
