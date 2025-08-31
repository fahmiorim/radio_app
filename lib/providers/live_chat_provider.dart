import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/live_message_model.dart';
import '../services/live_chat_socket_service.dart';

class LiveChatProvider with ChangeNotifier {
  final LiveChatSocketService _svc = LiveChatSocketService.I;

  final List<ChatMessage> _messages = [];
  final List<OnlineUser> _onlineUsers = [];

  bool _isLive = false;
  bool _isLoading = false;
  bool _isLoadingMessages = false;
  bool _hasMoreMessages = true;
  bool _isSocketInitialized = false;
  bool _statusSubscribed = false;
  bool _chatSubscribed = false;
  bool _presenceSubscribed = false;
  int? _subscribedRoomId;

  int _currentPage = 1;
  final int _messagesPerPage = 20;
  int? _currentRoomId;

  List<ChatMessage> get messages => _messages;
  List<OnlineUser> get onlineUsers => _onlineUsers;
  bool get isLive => _isLive;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get hasMoreMessages => _hasMoreMessages;
  int? get currentRoomId => _currentRoomId;

  Future<void> init(int roomId) async {
    _currentRoomId = roomId;
    _isLoading = true;
    notifyListeners();

    try {
      await _initializeSocket();
      await checkLiveStatus();
    } catch (e) {
      _isLoading = false;
      _isLive = false;
      notifyListeners();
    }
  }

  Future<void> _initializeSocket() async {
    if (_isSocketInitialized) return;

    await _svc.connect();
    _isSocketInitialized = true;

    if (!_statusSubscribed) {
      try {
        await _svc.subscribeStatus(
          onUpdated: (roomId, status) {
            final isLive = (status.toLowerCase() == 'started');
            _isLive = isLive;
            if (!isLive) {
              _messages.clear();
              _onlineUsers.clear();
              unawaited(_unsubscribeRoom());
            } else {
              _currentRoomId = roomId ?? _currentRoomId;
              _currentPage = 1;
              _hasMoreMessages = true;
              _messages.clear();
              unawaited(_subscribeRoom(_currentRoomId!));
              unawaited(loadOldMessages());
            }
            notifyListeners();
          },
        );
        _statusSubscribed = true;
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('Already subscribed')) {
          _statusSubscribed = true;
        } else {
          rethrow;
        }
      }
    }
  }

  Future<void> _subscribeRoom(int roomId) async {
    if (_subscribedRoomId == roomId && _chatSubscribed && _presenceSubscribed) {
      return;
    }

    await _unsubscribeRoom();

    try {
      await _svc.subscribePublic(
        roomId: roomId,
        onMessage: (LiveChatMessage msg) {
          if (_messages.any((m) => m.id == msg.id.toString())) return;
          _messages.add(
            ChatMessage(
              id: msg.id.toString(),
              username: msg.name,
              message: msg.message,
              timestamp: msg.timestamp,
              userAvatar: msg.avatar,
            ),
          );
          notifyListeners();
        },
        onSystem: (_) {},
      );
      _chatSubscribed = true;

      await _svc.subscribePresence(
        roomId: roomId,
        onHere: (users) {
          _onlineUsers
            ..clear()
            ..addAll(users.map((u) {
              final name = (u['name'] ?? u['username'] ?? 'Unknown').toString();
              return OnlineUser(
                id: u['id'].toString(),
                username: name,
                joinTime: DateTime.now(),
              );
            }));
          notifyListeners();
        },
        onJoining: (user) {
          final name =
              (user['name'] ?? user['username'] ?? 'Unknown').toString();
          _onlineUsers.add(
            OnlineUser(
              id: user['id'].toString(),
              username: name,
              joinTime: DateTime.now(),
            ),
          );
          notifyListeners();
        },
        onLeaving: (user) {
          _onlineUsers.removeWhere((u) => u.id == user['id'].toString());
          notifyListeners();
        },
      );
      _presenceSubscribed = true;
      _subscribedRoomId = roomId;
    } catch (e) {
      // ignore errors
    }
  }

  Future<void> _unsubscribeRoom() async {
    if (_subscribedRoomId != null) {
      if (_chatSubscribed) {
        await _svc.unsubscribePublic(_subscribedRoomId!);
        _chatSubscribed = false;
      }
      if (_presenceSubscribed) {
        await _svc.unsubscribePresence(_subscribedRoomId!);
        _presenceSubscribed = false;
      }
    }
    _onlineUsers.clear();
    _subscribedRoomId = null;
  }

  Future<void> checkLiveStatus() async {
    try {
      final status = await _svc.checkLiveStatus();
      _isLive = status['isLive'] == true;
      final liveRoom = status['liveRoom'] as Map<String, dynamic>?;
      if (liveRoom != null && liveRoom['id'] != null) {
        _currentRoomId = liveRoom['id'] as int;
        if (_isLive) {
          _currentPage = 1;
          _hasMoreMessages = true;
          _messages.clear();
          await _subscribeRoom(_currentRoomId!);
          await loadOldMessages();
        } else {
          _messages.clear();
          _onlineUsers.clear();
          await _unsubscribeRoom();
        }
      } else if (!_isLive) {
        _messages.clear();
        _onlineUsers.clear();
        await _unsubscribeRoom();
      }
    } catch (_) {
      _isLive = false;
      _messages.clear();
      _onlineUsers.clear();
      await _unsubscribeRoom();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOldMessages() async {
    if (_isLoadingMessages || !_hasMoreMessages || _currentRoomId == null) {
      return;
    }

    _isLoadingMessages = true;
    notifyListeners();

    try {
      final messages = await _svc.fetchChatHistory(
        roomId: _currentRoomId!,
        page: _currentPage,
        perPage: _messagesPerPage,
      );

      if (messages.isEmpty) {
        _hasMoreMessages = false;
      } else {
        final newMessages = messages
            .map(
              (msg) => ChatMessage(
                id: msg['id'].toString(),
                username: msg['name'] ?? 'Unknown',
                message: msg['message'] ?? '',
                timestamp: DateTime.parse(msg['timestamp']),
              ),
            )
            .toList();
        _messages.insertAll(0, newMessages);
        _currentPage++;
      }
    } catch (_) {
      // ignore
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text, {Function(String)? onError}) async {
    if (text.isEmpty || _currentRoomId == null) return;

    try {
      await _svc.sendMessage(
        roomId: _currentRoomId!,
        message: text,
        onSuccess: (LiveChatMessage msg) {
          _messages.add(
            ChatMessage(
              id: msg.id.toString(),
              username: msg.name,
              message: msg.message,
              timestamp: msg.timestamp,
              userAvatar: msg.avatar,
            ),
          );
          notifyListeners();
        },
        onError: (err) {
          onError?.call(err);
        },
      );
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  String formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'baru saja';
    if (difference.inHours < 1) return '${difference.inMinutes} menit lalu';
    if (difference.inDays < 1) return '${difference.inHours} jam lalu';
    return '${difference.inDays} hari lalu';
  }

  Future<void> disposeSocket() async {
    try {
      await _unsubscribeRoom();
      await _svc.disconnect();
    } catch (_) {}
  }

  @override
  void dispose() {
    unawaited(_unsubscribeRoom());
    _svc.disconnect();
    super.dispose();
  }
}
