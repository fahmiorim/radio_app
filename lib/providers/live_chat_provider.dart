import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/chat_model.dart';
import '../models/live_message_model.dart';
import '../services/live_chat_socket_service.dart';

class LiveChatProvider with ChangeNotifier {
  final int roomId;
  LiveChatProvider({required this.roomId});

  final LiveChatSocketService _svc = LiveChatSocketService.I;

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

  int? _currentRoomId; // dari API status (bisa beda dengan roomId default)
  int? get currentRoomId => _currentRoomId;

  // ==== INIT ====
  Future<void> init() async {
    if (_socketReady) return;

    await _svc.connect();
    _socketReady = true;

    await _subscribeStatusOnce();
    await _subscribePresenceOnce();

    await refreshStatus();
  }

  // ==== STATUS ====
  Future<void> refreshStatus() async {
    _isLoading = true; notifyListeners();

    try {
      final s = await _svc.checkLiveStatus();
      _isLive = s['isLive'] == true;

      final liveRoom = s['liveRoom'] as Map<String, dynamic>?;
      if (liveRoom != null && liveRoom['id'] != null) {
        _currentRoomId = liveRoom['id'] as int;
      } else {
        _currentRoomId = roomId; // fallback ke roomId dari constructor
      }

      if (_isLive) {
        _page = 1; _hasMore = true; _messages.clear();
        await _subscribePublicOnce();
        await loadMore();
      } else {
        _messages.clear();
        // presence tetap aktif untuk lihat user online kalau backend mendukung,
        // kalau tidak ingin: _onlineUsers.clear();
      }
    } catch (_) {
      _isLive = false;
      _messages.clear();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> _subscribeStatusOnce() async {
    if (_statusSubscribed) return;
    
    // Set up status update callback
    _svc.setCallbacks(
      onStatusUpdated: (data) {
        final isLive = data['isLive'] == true || data['status'] == 'started';
        _isLive = isLive;

        if (!isLive) {
          _messages.clear();
          notifyListeners();
          return;
        }

        // Live started → update room, subscribe to public chat, and load history
        _currentRoomId = data['roomId'] ?? _currentRoomId ?? roomId;
        _page = 1; _hasMore = true; _messages.clear();
        notifyListeners();

        _subscribePublicOnce();
        loadMore();
      },
    );
    
    // Subscribe to status channel
    await _svc.subscribeToStatus();
    _statusSubscribed = true;
  }

  // ==== PRESENCE (ONLINE USERS) ====
  Future<void> _subscribePresenceOnce() async {
    if (_presenceSubscribed) return;

    // Set up presence callbacks
    _svc.setCallbacks(
      onUserJoined: (channel, userData) {
        final user = userData as Map<String, dynamic>;
        final id = (user['userId'] ?? '').toString();
        if (_onlineUsers.indexWhere((x) => x.id == id) == -1) {
          _onlineUsers.add(OnlineUser(
            id: id,
            username: (user['userInfo']?['name'] ?? user['userInfo']?['username'] ?? 'User').toString(),
            userAvatar: (user['userInfo']?['avatar'] ?? user['userInfo']?['photo'])?.toString(),
            joinTime: DateTime.now(),
          ));
          notifyListeners();
        }
      },
      onUserLeft: (channel, userData) {
        final user = userData as Map<String, dynamic>;
        final id = (user['userId'] ?? '').toString();
        _onlineUsers.removeWhere((x) => x.id == id);
        notifyListeners();
      },
    );

    // Subscribe to presence channel
    await _svc.subscribeToPresence(roomId);
    _presenceSubscribed = true;
  }

  // ==== PUBLIC CHAT (REALTIME MESSAGE) ====
  Future<void> _subscribePublicOnce() async {
    if (_publicSubscribed) return;
    final rid = _currentRoomId ?? roomId;
    
    _isLoading = true;
    notifyListeners();

    try {
      // Set up message received callback
      _svc.setCallbacks(
        onMessageReceived: (channel, messageData) {
          try {
            final msg = LiveChatMessage.fromJson(
              messageData is Map<String, dynamic> 
                  ? messageData 
                  : {'id': '${DateTime.now().millisecondsSinceEpoch}'}
            );
            
            // Avoid duplicates if history + realtime overlap
            if (_messages.any((m) => m.id == msg.id.toString())) return;

            _messages.add(ChatMessage(
              id: msg.id.toString(),
              username: msg.name,
              message: msg.message,
              timestamp: msg.timestamp,
              userAvatar: msg.avatar,
            ));
            notifyListeners();
          } catch (e) {
            debugPrint('Error processing message: $e');
          }
        },
      );

      // Subscribe to chat channel
      await _svc.subscribeToChat(rid);
      _publicSubscribed = true;
    } catch (e) {
      debugPrint('Error subscribing to public chat: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==== HISTORY (PAGINATION) ====
  Future<void> loadMore() async {
    if (!_isLive || !_hasMore) return;

    final rid = _currentRoomId ?? roomId;
    try {
      final data = await _svc.fetchChatHistory(
        roomId: rid,
        page: _page,
        perPage: _perPage,
      );

      if (data.isEmpty) {
        _hasMore = false;
      } else {
        final newMsgs = data.map((m) => ChatMessage(
          id: '${m['id']}',
          username: m['name'] ?? 'Unknown',
          message: m['message'] ?? '',
          timestamp: DateTime.parse(m['timestamp']),
        )).toList();

        // older first → masukkan di atas list
        _messages.insertAll(0, newMsgs);
        _page++;
      }
    } catch (_) {
      // ignore error tarik history
    } finally {
      notifyListeners();
    }
  }

  // ==== SEND (optimistic) ====
  Future<void> send(String text, {String username = 'Anda'}) async {
    final t = text.trim();
    if (t.isEmpty || !_isLive) return;

    // Optimistic UI
    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      message: t,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    // TODO: kirim ke backend:
    // await _svc.sendMessage(roomId: _currentRoomId ?? roomId, message: t);
  }

  // ==== FORMATTER (opsional dipakai Screen) ====
  String formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'baru saja';
    if (difference.inHours < 1) return '${difference.inMinutes} menit lalu';
    if (difference.inDays < 1) return '${difference.inHours} jam lalu';
    return '${difference.inDays} hari lalu';
  }

  // ==== LIFECYCLE ====
  // Jangan disconnect di dispose (hot reload sering panggil dispose).
  @override
  void dispose() {
    super.dispose();
  }

  // Panggil dari dispose() screen saat benar-benar keluar.
  Future<void> shutdown() async {
    try { await _svc.unsubscribePublic(_currentRoomId ?? roomId); } catch (_) {}
    try { await _svc.unsubscribePresence(roomId); } catch (_) {}
    try { await _svc.unsubscribeStatus(); } catch (_) {}
    try { await _svc.disconnect(); } catch (_) {}
  }
}
