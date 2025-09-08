import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:radio_odan_app/models/chat_model.dart';
import 'package:radio_odan_app/models/live_message_model.dart';

import 'package:radio_odan_app/services/live_chat_service.dart';
import 'package:radio_odan_app/services/live_chat_socket_service.dart';

class LiveChatProvider with ChangeNotifier {
  final int roomId;
  LiveChatProvider({required this.roomId});

  // Services
  final LiveChatService _http = LiveChatService.I;
  final LiveChatSocketService _sock = LiveChatSocketService.I;

  // ---- STATE ----
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  final List<OnlineUser> _onlineUsers = [];
  List<OnlineUser> get onlineUsers => List.unmodifiable(_onlineUsers);

  bool _isLive = false;
  bool get isLive => _isLive;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  // pagination
  int _page = 1;
  final int _perPage = 20;

  // connection/subscription guards
  bool _socketReady = false;
  bool _statusSubscribed = false;
  bool _presenceSubscribed = false;
  bool _publicSubscribed = false;

  int? _currentRoomId;
  int? get currentRoomId => _currentRoomId;

  // Track current user ID to prevent self-message duplicates
  int? _currentUserId;

  int? _listenerId;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ==== INIT ====
  Future<void> init() async {
    if (_isInitialized) return;

    // 1) connect socket (sekali)
    if (!_socketReady) {
      await _sock.connect();
      _socketReady = true;
    }

    // 2) pasang callbacks realtime (sekali aja, sebelum subscribe)
    _wireRealtimeCallbacks();

    // 3) subscribe status & presence (sekali)
    await _subscribeStatusOnce();
    await _subscribePresenceOnce();

    // 4) initial HTTP load status + messages
    await refreshStatus();

    // join listener to track listener count
    try {
      final res = await _http.joinListener(roomId);
      final lid = res['listenerId'];
      if (lid is int) {
        _listenerId = lid;
      } else if (lid != null) {
        _listenerId = int.tryParse(lid.toString());
      }
    } catch (_) {}

    _isInitialized = true;
  }

  // === Realtime callbacks wiring ===
  void _wireRealtimeCallbacks() {
    _sock.setCallbacks(
      onStatusUpdate: (data) {
        // event: LiveRoomStatusUpdated
        final isLive = data['is_live'] == true || data['status'] == 'started';
        _isLive = isLive;

        if (!isLive) {
          _messages.clear();
          notifyListeners();
          return;
        }

        // update roomId jika dikirim
        final rid = data['roomId'] ?? data['room_id'];
        if (rid is int) _currentRoomId = rid;

        // saat live start → subscribe chat + tarik history awal
        _page = 1;
        _hasMore = true;
        _messages.clear();
        notifyListeners();
        _subscribePublicOnce();
        loadMore();
      },
      onUserJoined: (channel, user) {
        final map = (user);
        final id = (map['userId'] ?? '').toString();
        if (_onlineUsers.indexWhere((x) => x.id == id) == -1) {
          final username =
              (map['userInfo']?['name'] ??
                      map['userInfo']?['username'] ??
                      'User')
                  .toString();

          _onlineUsers.add(
            OnlineUser(
              id: id,
              username: username,
              userAvatar:
                  (map['userInfo']?['avatar'] ?? map['userInfo']?['photo'])
                      ?.toString(),
              joinTime: DateTime.now(),
            ),
          );

          // Add join notification message
          final isCurrentUser =
              _currentUserId != null && id == _currentUserId.toString();
          final message = isCurrentUser
              ? '🎉 Anda telah bergabung ke siaran'
              : '🎉 $username bergabung ke siaran';

          _messages.add(
            ChatMessage(
              id: 'join_${DateTime.now().millisecondsSinceEpoch}_$id',
              username: 'System',
              message: message,
              timestamp: DateTime.now(),
              isSystemMessage: true,
              isJoinNotification: true,
            ),
          );

          notifyListeners();
        }
      },
      onUserLeft: (channel, user) {
        final id = (user['userId'] ?? '').toString();
        final userLeft = _onlineUsers.firstWhere(
          (x) => x.id == id,
          orElse: () =>
              OnlineUser(id: '', username: 'User', joinTime: DateTime.now()),
        );

        _onlineUsers.removeWhere((x) => x.id == id);

        // Add leave notification message if the user was in the list
        if (userLeft.id.isNotEmpty) {
          _messages.add(
            ChatMessage(
              id: 'leave_${DateTime.now().millisecondsSinceEpoch}_$id',
              username: 'System',
              message: '👋 ${userLeft.username} meninggalkan siaran',
              timestamp: DateTime.now(),
              isSystemMessage: true,
            ),
          );
        }

        notifyListeners();
      },
      onMessage: (channel, messageData) {
        try {
          final msg = LiveChatMessage.fromJson(messageData);
          final messageId = msg.id.toString();

          // Skip if this is a message from the current user
          if (_currentUserId != null && msg.userId == _currentUserId) {
            return;
          }

          // Skip if this is a pending message we're already handling
          if (_pendingMessageIds.any((id) => messageId.contains(id))) {
            return;
          }

          // Check for duplicates by ID
          final isDuplicate = _messages.any((m) => m.id == messageId);
          if (isDuplicate) return;

          _messages.add(
            ChatMessage(
              id: messageId,
              username: msg.name,
              message: msg.message,
              timestamp: msg.timestamp,
              userAvatar: msg.avatar,
            ),
          );

          // Sort messages by timestamp to maintain order
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          notifyListeners();
        } catch (e) {
          rethrow;
        }
      },
      onSystem: (_) {},
    );
  }

  // ==== STATUS (HTTP) ====
  Future<void> refreshStatus() async {
    _isLoading = true;
    notifyListeners();
    try {
      final s = await _http.fetchGlobalStatus(); // <-- pakai endpoint global
      _isLive = s.isLive;
      _currentRoomId = s.roomId ?? roomId;

      if (_isLive) {
        _page = 1;
        _hasMore = true;
        _messages.clear();
        await _subscribePublicOnce();
        await loadMore();
      } else {
        _messages.clear();
      }
    } catch (e) {
      _isLive = false;
      _messages.clear();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _subscribeStatusOnce() async {
    if (_statusSubscribed) return;
    await _sock.subscribeToStatus();
    _statusSubscribed = true;
  }

  // ==== PRESENCE ====
  Future<void> _subscribePresenceOnce() async {
    if (_presenceSubscribed) return;
    await _sock.subscribeToPresence(roomId);
    _presenceSubscribed = true;
  }

  // ==== PUBLIC CHAT (REALTIME) ====
  Future<void> _subscribePublicOnce() async {
    if (_publicSubscribed) return;
    final rid = _currentRoomId ?? roomId;

    _isLoading = true;
    notifyListeners();

    try {
      await _sock.subscribeToChat(rid);
      _publicSubscribed = true;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==== HISTORY (HTTP + PAGINATION) ====
  bool _isLoadingMore = false;
  DateTime? _lastFetchTime;
  static const Duration _fetchCooldown = Duration(seconds: 1);

  Future<void> loadMore() async {
    // Prevent multiple concurrent fetches
    if (_isLoadingMore || !_isLive || !_hasMore) return;

    // Debounce rapid successive calls
    final now = DateTime.now();
    if (_lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _fetchCooldown) {
      return;
    }

    _isLoadingMore = true;
    _lastFetchTime = now;

    final rid = _currentRoomId ?? roomId;
    try {
      final items = await _http.fetchMessages(
        rid,
        page: _page,
        perPage: _perPage,
      );

      if (items.isEmpty) {
        _hasMore = false;
      } else {
        final newMsgs = items
            .map(
              (m) => ChatMessage(
                id: m.id.toString(),
                username: m.name,
                message: m.message,
                timestamp: m.timestamp,
                userAvatar: m.avatar,
              ),
            )
            .toList();

        // Filter out any messages we already have
        final existingIds = _messages.map((m) => m.id).toSet();
        final uniqueNewMsgs = newMsgs
            .where((m) => !existingIds.contains(m.id))
            .toList();

        if (uniqueNewMsgs.isNotEmpty) {
          _messages.insertAll(0, uniqueNewMsgs); // older first, prepend
          _page++;
        } else {
          // If we didn't get any new messages, we've probably reached the end
          _hasMore = false;
        }
      }
    } catch (e) {
      // Don't rethrow here to prevent breaking the UI
      debugPrint('Error loading more messages: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ==== SEND (HTTP; optimistic UI) ====
  final Set<String> _pendingMessageIds = {};

  // Set current user ID after login
  void setCurrentUserId(int userId) {
    _currentUserId = userId;
  }

  Future<void> send(
    String text, {
    String username = 'Anda',
    String? userAvatar,
  }) async {
    final t = text.trim();
    if (t.isEmpty || !_isLive) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    // Add to pending set
    _pendingMessageIds.add(tempId);

    // optimistic update
    _messages.add(
      ChatMessage(
        id: tempId,
        username: username,
        message: t,
        timestamp: now,
        userAvatar: userAvatar,
      ),
    );
    notifyListeners();

    try {
      final sent = await _http.sendMessage(_currentRoomId ?? roomId, t);

      // Remove the temporary message
      _messages.removeWhere((m) => m.id == tempId);
      // Check if the confirmed message already exists
      final finalId = sent.id.toString();
      if (_messages.any((m) => m.id == finalId)) {
        _pendingMessageIds.remove(tempId);
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        notifyListeners();
        return;
      }

      // Add the confirmed message from server
      _messages.add(
        ChatMessage(
          id: finalId,
          username: sent.name,
          message: sent.message,
          timestamp: sent.timestamp,
          userAvatar: sent.avatar,
        ),
      );

      // Remove from pending set
      _pendingMessageIds.remove(tempId);

      // Sort messages by timestamp to maintain order
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      notifyListeners();
    } catch (e) {
      // rollback optimistic update
      _messages.removeWhere((m) => m.id == tempId);
      _pendingMessageIds.remove(tempId);
      notifyListeners();
      rethrow;
    }
  }

  // ==== FORMATTER ====
  String formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
    // (opsional: pakai intl untuk format yang lebih bagus)
  }

  // ==== LIFECYCLE ====
  Future<void> leaveRoom() async {
    if (_listenerId == null) return;
    try {
      await _http.leaveListener(_listenerId!);
    } catch (_) {}
    _listenerId = null;
  }

  Future<void> shutdown() async {
    await leaveRoom();
    try {
      await _sock.unsubscribePublic(_currentRoomId ?? roomId);
    } catch (_) {}
    try {
      await _sock.unsubscribePresence(roomId);
    } catch (_) {}
    try {
      await _sock.unsubscribeStatus();
    } catch (_) {}
    try {
      await _sock.disconnect();
    } catch (_) {}
  }
}
