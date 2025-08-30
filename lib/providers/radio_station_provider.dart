import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/radio_station.dart';
import '../audio/audio_player_manager.dart';

class RadioStationProvider with ChangeNotifier {
  RadioStation? _currentStation;
  bool _isPlaying = false;

  RadioStation? get currentStation => _currentStation;
  bool get isPlaying => _isPlaying;

  // Default radio station
  static final RadioStation defaultStation = RadioStation(
    title: "Radio Barakab",
    host: "Barakab Radio",
    coverUrl: "assets/cover.jpg",
    streamUrl: "https://rsb.batubarakab.go.id:8000/radio.mp3",
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
  }

  void setStation(RadioStation station) {
    _currentStation = station;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> togglePlayPause() async {
    if (_currentStation == null) {
      log('No station selected');
      return;
    }

    try {
      if (_isPlaying) {
        log('Pausing playback');
        await _audioManager.pause();
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
