import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

import '../audio/audio_player_manager.dart';
import '../models/now_playing.dart';
import '../models/radio_station.dart';

class RadioStationProvider with ChangeNotifier {
  // --- STATE ---
  RadioStation? _currentStation;
  bool _isPlaying = false;
  NowPlayingInfo? _nowPlaying;

  // --- WS / Polling ---
  WebSocketChannel? _ws;
  StreamSubscription? _wsSub;
  Timer? _reconnectTimer;
  Timer? _pollingTimer;
  int _reconnectAttempts = 0;

  // --- GETTERS ---
  RadioStation? get currentStation => _currentStation;
  bool get isPlaying => _isPlaying;
  NowPlayingInfo? get nowPlaying => _nowPlaying;

  // --- DEFAULT STATION CONFIG ---
  // Tambahkan semua endpoint yang dibutuhkan di RadioStation (atau ganti sesuai modelmu)
  static final RadioStation defaultStation = RadioStation(
    title: "ODAN 89,3 FM",
    host: "Host Odan",
    coverUrl: "assets/cover.jpg",
    streamUrl: "https://rsb.batubarakab.go.id:8000/radio.mp3",
    // ini bukan lagi 'nowPlayingUrl' untuk WS; kita pakai 3 properti terpisah di bawah
    nowPlayingUrl: "https://rsb.batubarakab.go.id/api/nowplaying_static/odan_fm.json",
  );

  // Konfigurasi WS/SSE & polling untuk station
  static const String _stationShortcode = 'odan_fm';
  static const String _wsUrl =
      'wss://rsb.batubarakab.go.id/api/live/nowplaying/websocket';
  static const String _staticNowPlayingUrl =
      'https://rsb.batubarakab.go.id/api/nowplaying_static/odan_fm.json';

  final AudioPlayerManager _audioManager = AudioPlayerManager();
  StreamSubscription<PlayerState>? _playerStateSubscription;

  RadioStationProvider() {
    _currentStation = defaultStation;

    // Sinkronkan state dengan just_audio
    _playerStateSubscription = _audioManager.playerStateStream.listen((state) {
      final now = state.playing;
      if (_isPlaying != now) {
        _isPlaying = now;
        notifyListeners();
      }
    });

    // Mulai koneksi WS (dengan fallback polling kalau gagal)
    _connectNowPlayingWS();
  }

  void setStation(RadioStation station) {
    _currentStation = station;
    // ganti station -> restart WS & polling
    _teardownRealtime();
    _connectNowPlayingWS();
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _teardownRealtime();
    super.dispose();
  }

  // -------------------------------
  // Realtime via WebSocket AzuraCast
  // -------------------------------
  void _connectNowPlayingWS() {
    _teardownRealtime(); // pastikan bersih

    try {
      _ws = WebSocketChannel.connect(Uri.parse(_wsUrl));

      // Kirim frame subscribe segera setelah connect
      final subMsg = {
        "subs": {
          "station:$_stationShortcode": {"recover": true}
        }
      };
      _ws!.sink.add(jsonEncode(subMsg));

      _wsSub = _ws!.stream.listen(
        (raw) {
          try {
            final msg = jsonDecode(raw as String);

            Map<String, dynamic>? np;

            // Pesan awal (cached publications)
            if (msg is Map && msg.containsKey('connect')) {
              final subs = msg['connect']?['subs'] as Map?;
              subs?.forEach((_, sub) {
                final pubs = sub['publications'] as List? ?? const [];
                for (final pub in pubs) {
                  final data = (pub as Map)['data'] as Map?;
                  if (data != null && data['np'] != null) {
                    np = data['np'] as Map<String, dynamic>;
                  }
                }
              });
            }

            // Update realtime
            if (msg is Map && msg.containsKey('pub')) {
              final data = msg['pub']?['data'] as Map?;
              if (data != null && data['np'] != null) {
                np = data['np'] as Map<String, dynamic>;
              }
            }

            if (np != null) {
              _updateNowPlayingFromNp(np!);
              _reconnectAttempts = 0; // sukses terima data -> reset backoff
            }
          } catch (e) {
            log('WS parse error: $e');
          }
        },
        onError: (e) {
          log('WebSocket error: $e');
          _startPollingFallback(); // aktifkan polling sementara
          _scheduleReconnect();
        },
        onDone: () {
          log('WebSocket closed');
          _startPollingFallback();
          _scheduleReconnect();
        },
      );
    } catch (e) {
      log('Error connecting WS: $e');
      _startPollingFallback();
      _scheduleReconnect();
    }
  }

  void _updateNowPlayingFromNp(Map<String, dynamic> np) {
    // NOTE:
    // Struktur np (dari WS) ≈ struktur /api/nowplaying/<station>.
    // Jika modelmu `NowPlayingInfo.fromJson` sudah cocok, langsung pakai:
    try {
      // Kalau modelmu mengharapkan 'now_playing' saja, kamu bisa:
      // final Map<String, dynamic> modelJson = np['now_playing'] ?? np;
      final Map<String, dynamic> modelJson = np;

      _nowPlaying = NowPlayingInfo.fromJson(modelJson);
      notifyListeners();
    } catch (e) {
      log('Mapping NowPlaying error: $e');
    }
  }

  void _teardownRealtime() {
    _wsSub?.cancel();
    _wsSub = null;
    _ws?.sink.close();
    _ws = null;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    // Exponential backoff: 2, 4, 8, ... max 60s
    _reconnectAttempts = (_reconnectAttempts + 1).clamp(1, 30);
    final secs = (2 << (_reconnectAttempts - 1));
    final wait = Duration(seconds: secs > 60 ? 60 : secs);
    log('Reconnecting WS in ${wait.inSeconds}s (attempt: $_reconnectAttempts)');
    _reconnectTimer = Timer(wait, _connectNowPlayingWS);
  }

  // -------------------------------
  // Fallback Polling (Static JSON)
  // -------------------------------
  void _startPollingFallback() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 12), (_) async {
      try {
        final res = await http.get(Uri.parse(_staticNowPlayingUrl));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          // respons static: { station, listeners, live, now_playing, ... }
          final np = data; // langsung pass (sesuaikan jika modelmu butuh subset)
          _updateNowPlayingFromNp(np);
        } else {
          log('Polling NP non-200: ${res.statusCode}');
        }
      } catch (e) {
        log('Polling NP error: $e');
      }
    });
  }

  // -------------------------------
  // Audio controls
  // -------------------------------
  Future<void> togglePlayPause() async {
    if (_currentStation == null) {
      log('No station selected');
      return;
    }

    try {
      if (_isPlaying) {
        await _audioManager.stop();
        _isPlaying = false;
      } else {
        await _audioManager.playRadio(_currentStation!);
        _isPlaying = true;
      }
      notifyListeners();
    } catch (e) {
      log('Error toggling play/pause: $e');
      _isPlaying = false;
      notifyListeners();
      rethrow;
    }
  }

  void setPlaying(bool playing) {
    if (_isPlaying != playing) {
      _isPlaying = playing;
      notifyListeners();
    }
  }
}
