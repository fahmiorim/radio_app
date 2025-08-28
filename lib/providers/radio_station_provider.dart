import 'package:flutter/foundation.dart';
import '../models/radio_station.dart';

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
    streamUrl: "https://api.barakab.go.id:8000/radio.mp3",
  );

  RadioStationProvider() {
    // Initialize with default station
    _currentStation = defaultStation;
  }

  void setStation(RadioStation station) {
    _currentStation = station;
    notifyListeners();
  }

  void setPlaying(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }
}
