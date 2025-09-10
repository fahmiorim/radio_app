import 'package:flutter/foundation.dart';

import 'package:radio_odan_app/services/live_chat_service.dart';
import 'package:radio_odan_app/services/live_chat_socket_service.dart';

class LiveStatusProvider with ChangeNotifier {
  final LiveChatService _http = LiveChatService.I;
  final LiveChatSocketService _socket = LiveChatSocketService.I;

  bool _isLive = false;
  int? _roomId;

  bool get isLive => _isLive;
  int? get roomId => _roomId;

  LiveStatusProvider() {
    _init();
  }

  void _init() {
    refresh();
    _socket.statusStream.listen((data) {
      final started = data['status'] == 'started' || data['is_live'] == true;
      final rid = data['room_id'] ?? data['roomId'];
      _isLive = started;
      _roomId = started ? _parseInt(rid) : null;
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    try {
      final status = await _http.fetchGlobalStatus();
      _isLive = status.isLive;
      _roomId = status.roomId;
      notifyListeners();
    } catch (_) {}
  }

  int? _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }
}
