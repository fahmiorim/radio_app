import 'dart:developer';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import '../models/radio_station.dart';

/// Manages audio playback for radio streams
/// Uses a singleton pattern to ensure only one instance exists
class AudioPlayerManager {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  static AudioPlayerManager get instance => _instance;

  final AudioPlayer _player = AudioPlayer();
  // Track current playing station and URL
  RadioStation? _currentStation;
  String? _currentUrl;

  AudioPlayerManager._internal() {
    _setupAudioSession();
  }

  Future<void> _setupAudioSession() async {
    try {
      final session = await AudioSession.instance;

      // Configure audio session for streaming
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ),
      );

      await _player.setAudioSource(
        AudioSource.uri(Uri.parse('')),
        preload: false,
      );
    } catch (e) {
      log('Error setting up audio session: $e');
      rethrow;
    }
  }

  AudioPlayer get player => _player;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  RadioStation? get currentStation => _currentStation;

  /// Mainkan radio dengan metadata dari RadioStation
  /// Play a radio station
  Future<void> playRadio(RadioStation station) async {
    final url = station.streamUrl;

    // Don't reinitialize if it's the same station and URL
    if (_currentStation?.id == station.id && _currentUrl == url) {
      if (_player.playing != true) {
        await _player.play();
      }
      return;
    }

    try {
      _currentStation = station;
      _currentUrl = url;
      final audioSource = AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: url,
          title: station.title,
          artist: station.host,
          artUri: Uri.parse(station.coverUrl),
        ),
      );

      // Set audio source directly without empty source first
      await _player.setAudioSource(
        audioSource,
        preload: true,
        initialPosition: Duration.zero,
        initialIndex: 0,
      );

      await _player.setVolume(1.0);
      await _player.play();
      await _player.seek(Duration.zero);

    } catch (e) {
      _currentStation = null;
      _currentUrl = null;
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      if (_player.playing) {
        await _player.pause();
      }
    } catch (e) {
      log('Error pausing playback: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      if (_currentUrl == null) {
        return;
      }

      await _player.pause();

      await _player.setAudioSource(
        AudioSource.uri(Uri.parse('')),
        preload: false,
      );
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse('')),
        preload: false,
      );

      await _player.stop();

      _currentStation = null;
      _currentUrl = null;
    } catch (e) {
      _currentStation = null;
      _currentUrl = null;
      rethrow;
    }
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (e) {
      log('Error disposing audio player: $e');
      rethrow;
    }
  }
}
