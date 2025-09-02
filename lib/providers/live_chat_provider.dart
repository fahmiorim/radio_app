import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/chat_model.dart';
import '../models/live_message_model.dart';
import '../services/live_chat_service.dart';
import '../services/live_chat_socket_service.dart';

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

  // socket flags
  bool _socketReady = false;
  bool _statusSubscribed = false;

  // dynamic room subscriptions
  int? _currentRoomId;
  int? get currentRoomId => _currentRoomId;
  int? _subscribedPublicRoomId;
  int? _subscribedPresenceRoomId;

  // dedupe
  final Set<String> _seenMessageIds = {}; // track ID yang sudah tampil
  final Set<String> _pendingTempIds = {}; // untuk optimistic UI

  // user
  int? _currentUserId;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ==== INIT ====
  Future<void> init() async {
    if (_isInitialized) return;

    if (!_socketReady) {
      await _sock.ensureConnected();
      _socketReady = true;
    }

    _wireRealtimeCallbacks();

    await _subscribeStatusOnce();

    // Initial status & messages
    await refreshStatus();

    _isInitialized = true;
  }

  // === Realtime callbacks wiring ===
  void _wireRealtimeCallbacks() {
    _sock.setCallbacks(
      onStatusUpdate: (data) async {
        final isLive = data['is_live'] == true || data['status'] == 'started';
        _isLive = isLive;

        if (!isLive) {
          _messages.clear();
          _onlineUsers.clear();
          _seenMessageIds.clear();
          notifyListeners();
          return;
        }

        // Update roomId jika ada
        final rid = _toInt(data['roomId'] ?? data['room_id']);
        if (rid != 0) {
          await _switchRoom(rid);
        }

        // reset pagination & fetch batch pertama
        _page = 1;
        _hasMore = true;
        _messages.clear();
        _onlineUsers.clear();
        _seenMessageIds.clear();
        notifyListeners();

        await _subscribePublicIfNeeded();
        await loadMore();
      },

      onSystem: (data) {
        // optional: tampilkan pesan sistem singkat
        final msg = data['message']?.toString();
        if (msg == null || msg.isEmpty) return;

        final systemMessage = ChatMessage(
          id: 'system-${DateTime.now().microsecondsSinceEpoch}',
          username: 'System',
          message: msg,
          timestamp:
              DateTime.tryParse('${data['timestamp']}') ?? DateTime.now(),
          isSystemMessage: true,
        );

        // tampilkan sebagai item ringan (tidak mengganggu dedupe normal)
        _messages.add(systemMessage);
        notifyListeners();
      },

      onUserJoined: (channel, user) {
        final userId = (user['userId'] ?? '').toString();
        final userInfo = user['userInfo'] is Map
            ? Map<String, dynamic>.from(user['userInfo'])
            : <String, dynamic>{};
        final username = userInfo['name']?.toString() ?? 'Unknown User';

        if (_onlineUsers.any((u) => u.id == userId)) return;

        _onlineUsers.add(
          OnlineUser(
            id: userId,
            username: username,
            userAvatar: userInfo['avatar']?.toString(),
            joinTime: DateTime.now(),
          ),
        );

        // notifikasi bergabung (opsional)
        final joinMessage = ChatMessage(
          id: 'join-$userId-${DateTime.now().microsecondsSinceEpoch}',
          username: username,
          message: 'telah bergabung ke ruang chat',
          timestamp: DateTime.now(),
          isJoinNotification: true,
        );
        _messages.add(joinMessage);

        notifyListeners();
      },

      onUserLeft: (channel, user) {
        final userId = (user['userId'] ?? '').toString();
        final userInfo = user['userInfo'] is Map
            ? Map<String, dynamic>.from(user['userInfo'])
            : <String, dynamic>{};
        final username = userInfo['name']?.toString() ?? 'User';

        _onlineUsers.removeWhere((u) => u.id == userId);

        // notifikasi keluar (opsional)
        final leaveMessage = ChatMessage(
          id: 'leave-$userId-${DateTime.now().microsecondsSinceEpoch}',
          username: username,
          message: 'telah meninggalkan ruang chat',
          timestamp: DateTime.now(),
          isSystemMessage: true,
        );
        _messages.add(leaveMessage);

        notifyListeners();
      },

      onMessage: (channel, messageData) {
        try {
          if (channel == 'message.deleted') {
            final delId = (messageData['id'] ?? '').toString();
            if (delId.isNotEmpty) {
              _messages.removeWhere((m) => m.id == delId);
              _seenMessageIds.remove(delId);
              notifyListeners();
            }
            return;
          }

          final msg = LiveChatMessage.fromJson(messageData);
          final messageId = msg.id.toString();

          // Skip messages from self (server echo)
          if (_currentUserId != null && msg.userId == _currentUserId) {
            return;
          }

          // Dedupe: skip jika sudah tampil
          if (_seenMessageIds.contains(messageId)) return;

          _seenMessageIds.add(messageId);
          _messages.add(
            ChatMessage(
              id: messageId,
              username: msg.name,
              message: msg.message,
              timestamp: msg.timestamp,
              userAvatar: msg.avatar,
            ),
          );

          // Urut kronologis
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          notifyListeners();
        } catch (_) {
          // swallow
        }
      },
    );
  }

  // ==== STATUS (HTTP) ====
  Future<void> refreshStatus() async {
    _isLoading = true;
    notifyListeners();
    try {
      final s = await _http.fetchGlobalStatus();
      _isLive = s.isLive;
      final rid = s.roomId ?? roomId;
      await _switchRoom(rid);

      if (_isLive) {
        _page = 1;
        _hasMore = true;
        _messages.clear();
        _seenMessageIds.clear();
        await _subscribePublicIfNeeded();
        await loadMore();
      } else {
        _messages.clear();
        _seenMessageIds.clear();
      }
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

  // ==== ROOM SWITCHING & SUBSCRIPTIONS ====
  Future<void> _switchRoom(int rid) async {
    if (_currentRoomId == rid) return;

    // Unsubscribe old channels (public & presence)
    if (_subscribedPublicRoomId != null) {
      await _sock.unsubscribePublic(_subscribedPublicRoomId!);
      _subscribedPublicRoomId = null;
    }
    if (_subscribedPresenceRoomId != null) {
      await _sock.unsubscribePresence(_subscribedPresenceRoomId!);
      _subscribedPresenceRoomId = null;
    }

    _currentRoomId = rid;

    // Subscribe new presence untuk room baru
    await _subscribePresenceIfNeeded();
  }

  Future<void> _subscribePresenceIfNeeded() async {
    final rid = _currentRoomId ?? roomId;
    if (_subscribedPresenceRoomId == rid) return;
    await _sock.subscribeToPresence(rid);
    _subscribedPresenceRoomId = rid;
  }

  Future<void> _subscribePublicIfNeeded() async {
    final rid = _currentRoomId ?? roomId;
    if (_subscribedPublicRoomId == rid) return;
    await _sock.subscribeToChat(rid);
    _subscribedPublicRoomId = rid;
  }

  // ==== HISTORY (HTTP + PAGINATION) ====
  Future<void> loadMore() async {
    if (!_isLive || !_hasMore) return;

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
            .where((m) {
              final idStr = m.id.toString();
              if (_seenMessageIds.contains(idStr)) return false;
              _seenMessageIds.add(idStr);
              return true;
            })
            .map((m) {
              return ChatMessage(
                id: m.id.toString(),
                username: m.name,
                message: m.message,
                timestamp: m.timestamp,
                userAvatar: m.avatar,
              );
            })
            .toList();

        // prepend agar urutan tetap kronologis (older duluan)
        _messages.insertAll(0, newMsgs);
        _page++;
      }
    } finally {
      notifyListeners();
    }
  }

  // ==== SEND (HTTP; optimistic UI) ====
  void setCurrentUserId(int userId) {
    _currentUserId = userId;
  }

  Future<void> send(String text, {String username = 'Anda'}) async {
    final t = text.trim();
    if (t.isEmpty || !_isLive) return;

    final tempId = 'temp_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();

    _pendingTempIds.add(tempId);

    // Optimistic add
    _seenMessageIds.add(tempId);
    _messages.add(
      ChatMessage(id: tempId, username: username, message: t, timestamp: now),
    );
    notifyListeners();

    try {
      final sent = await _http.sendMessage(_currentRoomId ?? roomId, t);

      // Remove temp
      _messages.removeWhere((m) => m.id == tempId);
      _seenMessageIds.remove(tempId);

      final finalId = sent.id.toString();
      if (_seenMessageIds.contains(finalId)) {
        // sudah masuk via socket
        _pendingTempIds.remove(tempId);
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        notifyListeners();
        return;
      }

      _seenMessageIds.add(finalId);
      _messages.add(
        ChatMessage(
          id: finalId,
          username: sent.name,
          message: sent.message,
          timestamp: sent.timestamp,
          userAvatar: sent.avatar,
        ),
      );

      _pendingTempIds.remove(tempId);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      notifyListeners();
    } catch (e) {
      // rollback
      _messages.removeWhere((m) => m.id == tempId);
      _seenMessageIds.remove(tempId);
      _pendingTempIds.remove(tempId);
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
  }

  // ==== LIFECYCLE ====
  Future<void> shutdown() async {
    try {
      if (_subscribedPublicRoomId != null) {
        await _sock.unsubscribePublic(_subscribedPublicRoomId!);
      }
    } catch (_) {}
    try {
      if (_subscribedPresenceRoomId != null) {
        await _sock.unsubscribePresence(_subscribedPresenceRoomId!);
      }
    } catch (_) {}
    try {
      await _sock.unsubscribeStatus();
    } catch (_) {}
    try {
      await _sock.disconnect();
    } catch (_) {}

    _subscribedPublicRoomId = null;
    _subscribedPresenceRoomId = null;
    _statusSubscribed = false;
    _socketReady = false;
  }

  // ==== helpers ====
  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
