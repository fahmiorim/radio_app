import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/radio_station.dart';

class AudioPlayerManager {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;

  late final AudioPlayer _player;
  String? _currentUrl;

  AudioPlayerManager._internal() {
    _player = AudioPlayer();
  }

  AudioPlayer get player => _player;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Mainkan radio dengan metadata dari RadioStation
  Future<void> playRadio(RadioStation station) async {
    final url = station.streamUrl;
    final needSetUrl = (_player.audioSource == null) || (_currentUrl != url);

    if (needSetUrl) {
      _currentUrl = url;

      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: url,
            title: station.title,
            artist: station.host,
            artUri: Uri.parse(station.coverUrl),
          ),
        ),
      );
    }

    if (!_player.playing) {
      await _player.play();
    }
  }

  Future<void> pause() async => await _player.pause();

  Future<void> stop() async {
    await _player.stop();
    _currentUrl = null;
  }

  void dispose() => _player.dispose();
}
