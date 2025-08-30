import 'dart:async';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../audio/audio_player_manager.dart';
import '../models/now_playing.dart';
import '../models/radio_station.dart';

class RadioStationProvider with ChangeNotifier {
  RadioStation? _currentStation;
  bool _isPlaying = false;
  NowPlayingInfo? _nowPlaying;
  WebSocketChannel? _nowPlayingChannel;
  StreamSubscription? _nowPlayingSubscription;

  RadioStation? get currentStation => _currentStation;
  bool get isPlaying => _isPlaying;
  NowPlayingInfo? get nowPlaying => _nowPlaying;

  // Default radio station
  static final RadioStation defaultStation = RadioStation(
    title: "ODAN 89,3 FM",
    host: "Host Odan",
    coverUrl: "assets/cover.jpg",
    streamUrl: "https://rsb.batubarakab.go.id:8000/radio.mp3",
    nowPlayingUrl: "wss://rsb.batubarakab.go.id/api/live/nowplaying/websocket",
  );

  final AudioPlayerManager _audioManager = AudioPlayerManager();
  StreamSubscription<PlayerState>? _playerStateSubscription;

  RadioStationProvider() {
    // Initialize with default station
    _currentStation = defaultStation;

    // Listen to player state changes
    _playerStateSubscription = _audioManager.playerStateStream.listen((state) {
      final isNowPlaying = state.playing;
      if (_isPlaying != isNowPlaying) {
        _isPlaying = isNowPlaying;
        notifyListeners();
      }
    });
    _connectNowPlaying();
  }

  void setStation(RadioStation station) {
    _currentStation = station;
    _connectNowPlaying();
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _nowPlayingSubscription?.cancel();
    _nowPlayingChannel?.sink.close();
    super.dispose();
  }

  void _connectNowPlaying() {
    final station = _currentStation;
    if (station == null) return;

    _nowPlayingSubscription?.cancel();
    _nowPlayingChannel?.sink.close();

    try {
      _nowPlayingChannel = WebSocketChannel.connect(
        Uri.parse(station.nowPlayingUrl),
      );
      _nowPlayingSubscription = _nowPlayingChannel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            _nowPlaying = NowPlayingInfo.fromJson(data);
            notifyListeners();
          } catch (e) {
            log('Error parsing now playing: $e');
          }
        },
        onError: (error) {
          log('WebSocket error: $error');
        },
      );
    } catch (e) {
      log('Error connecting WebSocket: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentStation == null) {
      log('No station selected');
      return;
    }

    try {
      if (_isPlaying) {
        log('Pausing playback');
        // Stop completely so that resuming fetches fresh audio and avoids delay
        await _audioManager.stop();
        _isPlaying = false;
      } else {
        log('Starting playback for ${_currentStation!.title}');
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
