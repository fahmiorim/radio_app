import 'dart:async';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

import '../audio/audio_player_manager.dart';
import '../models/now_playing.dart';
import '../models/radio_station.dart';

class RadioStationProvider with ChangeNotifier {
  RadioStation? _currentStation;
  bool _isPlaying = false;
  NowPlayingInfo? _nowPlaying;
  Timer? _nowPlayingTimer;

  RadioStation? get currentStation => _currentStation;
  bool get isPlaying => _isPlaying;
  NowPlayingInfo? get nowPlaying => _nowPlaying;

  // Default radio station
  static final RadioStation defaultStation = RadioStation(
    title: "Radio Barakab",
    host: "Barakab Radio",
    coverUrl: "assets/cover.jpg",
    streamUrl: "https://rsb.batubarakab.go.id:8000/radio.mp3",
    nowPlayingUrl: "https://rsb.batubarakab.go.id/api/nowplaying/odan_fm",
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

    // Fetch initial now playing info and refresh periodically
    fetchNowPlaying();
    _nowPlayingTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => fetchNowPlaying());
  }

  void setStation(RadioStation station) {
    _currentStation = station;
    fetchNowPlaying();
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _nowPlayingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchNowPlaying() async {
    final station = _currentStation;
    if (station == null) return;

    try {
      final response = await http.get(Uri.parse(station.nowPlayingUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _nowPlaying = NowPlayingInfo.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      log('Error fetching now playing: $e');
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
