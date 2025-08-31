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
          PusherConfig.authEndpoint,
          data: {
            'channel_name': channelName,
            'socket_id': socketId,
          },
        );
        return res.data;
      },
    );
    await _pusher.connect();
    _connected = true;
  }

  Future<void> disconnect() async {
    if (!_connected) return;
    await _pusher.disconnect();
    _connected = false;
  }

  Future<void> subscribePresence({
    required int roomId,
    required void Function(List<dynamic> users) onHere,
    required void Function(dynamic user) onJoining,
    required void Function(dynamic user) onLeaving,
  }) async {
    await _pusher.subscribe(
      channelName: 'presence-chat.room.$roomId',
      onSubscriptionSucceeded: (data) {
        if (data is Map &&
            data['presence'] is Map &&
            (data['presence']['hash'] is Map)) {
          final hash = Map<String, dynamic>.from(data['presence']['hash']);
          onHere(hash.values
              .map((e) => e is Map<String, dynamic>
                  ? e
                  : e is Map
                      ? Map<String, dynamic>.from(e)
                      : <String, dynamic>{})
              .toList());
        } else {
          onHere(const []);
        }
      },
      onMemberAdded: (member) => onJoining(member.userInfo ?? {}),
      onMemberRemoved: (member) => onLeaving(member.userInfo ?? {}),
    );
  }

  Future<void> subscribePublic({
    required int roomId,
    required void Function(LiveChatMessage message) onMessage,
    required void Function(Map<String, dynamic> data) onSystem,
  }) async {
    await _pusher.subscribe(
      channelName: 'chat.room.$roomId',
      onEvent: (event) {
        Map<String, dynamic> payload;
        if (event.data is String) {
          payload = jsonDecode(event.data as String) as Map<String, dynamic>;
        } else {
          payload = Map<String, dynamic>.from(event.data ?? {});
        }
        if (event.eventName == 'message.sent') {
          final map = payload['message'] is Map
              ? Map<String, dynamic>.from(payload['message'])
              : payload;
          onMessage(LiveChatMessage.fromJson(map));
        } else {
          onSystem(payload);
        }
      },
    );
  }

  Future<void> subscribeLike({
    required int roomId,
    required void Function(int likeCount) onUpdated,
  }) async {
    await _pusher.subscribe(
      channelName: 'like-room-$roomId',
      onEvent: (event) {
        Map<String, dynamic> payload;
        if (event.data is String) {
          payload = jsonDecode(event.data as String) as Map<String, dynamic>;
        } else {
          payload = Map<String, dynamic>.from(event.data ?? {});
        }
        if (event.eventName == 'LikeUpdated') {
          final count = payload['likeCount'] is int
              ? payload['likeCount']
              : int.tryParse(payload['likeCount']?.toString() ?? '') ?? 0;
          onUpdated(count);
        }
      },
    );
  }

  Future<void> subscribeStatus({
    required void Function(int roomId, String status) onUpdated,
  }) async {
    await _pusher.subscribe(
      channelName: 'live-room-status',
      onEvent: (event) {
        if (event.eventName == 'LiveRoomStatusUpdated') {
          Map<String, dynamic> payload;
          if (event.data is String) {
            payload = jsonDecode(event.data as String) as Map<String, dynamic>;
          } else {
            payload = Map<String, dynamic>.from(event.data ?? {});
          }
          final id = payload['liveRoomId'] is int
              ? payload['liveRoomId']
              : int.tryParse(payload['liveRoomId']?.toString() ?? '') ?? 0;
          final status = payload['status']?.toString() ?? '';
          onUpdated(id, status);
        }
      },
    );
  }
}
