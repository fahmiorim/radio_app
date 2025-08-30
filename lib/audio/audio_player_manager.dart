import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import '../models/radio_station.dart';

/// Manages audio playback for radio streams
/// Uses a singleton pattern to ensure only one instance exists
class AudioPlayerManager {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;

  late final AudioPlayer _player;
  // Track current playing station and URL
  RadioStation? _currentStation;
  String? _currentUrl;

  AudioPlayerManager._internal() {
    debugPrint('🔧 [AudioPlayer] Initializing AudioPlayerManager...');
    _player = AudioPlayer();
    _setupAudioSession();

    // Handle audio player state changes
    _player.playerStateStream.listen((state) {
      debugPrint(
        '🔄 [AudioPlayer] State - playing: ${state.playing}, processingState: ${state.processingState}',
      );
    });

    // Handle audio player events
    _player.playbackEventStream.listen(
      (event) {
        debugPrint(
          '🎵 [AudioPlayer] Event - state: ${event.processingState}, buffered: ${event.bufferedPosition}, duration: ${event.duration}',
        );
      },
      onError: (e, stackTrace) {
        debugPrint('❌ [AudioPlayer] Playback error: $e');
        debugPrint('📜 [AudioPlayer] Stack trace: $stackTrace');
        _currentUrl = null;
        _currentStation = null;
      },
    );

    // Handle sequence state changes
    _player.sequenceStateStream.listen((state) {
      debugPrint(
        '🔢 [AudioPlayer] Sequence - current index: ${state?.currentIndex}, sequence length: ${state?.sequence.length}',
      );
    });

    debugPrint('✅ [AudioPlayer] AudioPlayerManager initialized');
  }

  Future<void> _setupAudioSession() async {
    try {
      debugPrint('🔊 [AudioPlayer] Initializing audio session...');
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

      // Activate the audio session
      final isActive = await session.setActive(true);
      debugPrint('🎛️ [AudioPlayer] Audio session active: $isActive');

      // Set buffer duration for streaming
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse('')),
        preload: false,
      );

      // Set up error handling for the audio player
      _player.playbackEventStream.listen(
        (event) {
          debugPrint(
            '🎵 [AudioPlayer] Playback event: ${event.processingState}',
          );
          debugPrint('   - Buffered: ${event.bufferedPosition}');
          debugPrint('   - Duration: ${event.duration}');
        },
        onError: (e, stackTrace) {
          debugPrint('❌ [AudioPlayer] Playback error: $e');
          debugPrint('📜 [AudioPlayer] Stack trace: $stackTrace');
        },
      );

      // Listen for player state changes
      _player.playerStateStream.listen((state) {
        debugPrint(
          '🔄 [AudioPlayer] Player state - playing: ${state.playing}, processing: ${state.processingState}',
        );
      });

      debugPrint('✅ [AudioPlayer] Audio session and player initialized');
    } catch (e, stackTrace) {
      debugPrint('❌ [AudioPlayer] Error initializing audio session: $e');
      debugPrint('📜 [AudioPlayer] Stack trace: $stackTrace');
      rethrow;
    }
  }

  AudioPlayer get player => _player;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Mainkan radio dengan metadata dari RadioStation
  /// Play a radio station
  Future<void> playRadio(RadioStation station) async {
    final url = station.streamUrl;

    try {
      debugPrint('\n🚀 [AudioPlayer] ===== Starting playback process =====');
      debugPrint('📻 [AudioPlayer] Station: ${station.title}');
      debugPrint('🔗 [AudioPlayer] Stream URL: $url');

      if (url == _currentUrl) {
        debugPrint('ℹ️ [AudioPlayer] Already playing this station');
        return;
      }

      // Stop any existing playback
      debugPrint('⏹️ [AudioPlayer] Stopping any existing playback...');
      await _player.stop();

      // Update current station and URL
      _currentStation = station;
      _currentUrl = url;

      // Create audio source with metadata
      debugPrint('\n🎵 [AudioPlayer] Creating audio source with metadata...');
      debugPrint('   - Title: ${station.title}');
      debugPrint('   - Host: ${station.host}');
      debugPrint('   - Cover: ${station.coverUrl}');

      // Configure the audio source for streaming
      final audioSource = AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: url,
          title: station.title,
          artist: station.host,
          artUri: Uri.parse(station.coverUrl),
        ),
      );

      debugPrint('\n🔧 [AudioPlayer] Configuring audio source...');
      try {
        // Clear any existing audio source first
        await _player.setAudioSource(
          AudioSource.uri(Uri.parse('')),
          preload: false,
        );

        // Set the new audio source
        await _player.setAudioSource(
          audioSource,
          preload: true,
          initialPosition: Duration.zero,
          initialIndex: 0,
        );

        debugPrint('✅ [AudioPlayer] Audio source configured successfully');
      } catch (error) {
        debugPrint('❌ [AudioPlayer] Error setting audio source: $error');
        _currentStation = null;
        _currentUrl = null;
        rethrow;
      }

      // Start playback with error handling
      debugPrint('\n▶️ [AudioPlayer] Starting playback...');
      try {
        // Set volume to maximum
        await _player.setVolume(1.0);

        // Start playback
        await _player.play();

        // Wait for buffering
        await _player.seek(Duration.zero);

        debugPrint('🎉 [AudioPlayer] Playback started successfully!');

        // Log the current state after a short delay
        await Future.delayed(const Duration(seconds: 3));

        final state = _player.playerState;
        debugPrint('\n📊 [AudioPlayer] Current state:');
        debugPrint('   - Playing: ${state.playing}');
        debugPrint('   - Processing state: ${state.processingState}');
        debugPrint('   - Volume: ${_player.volume}');
        debugPrint('   - Buffered: ${_player.bufferedPosition}');
        debugPrint('   - Duration: ${_player.duration}');

        // If still not playing after delay, try to recover
        if (!state.playing) {
          debugPrint(
            '⚠️ [AudioPlayer] Playback not started, attempting recovery...',
          );
          await _player.play();
        }
      } catch (e, stackTrace) {
        debugPrint('❌ [AudioPlayer] Playback failed: $e');
        debugPrint('📜 [AudioPlayer] Stack trace: $stackTrace');
        _currentStation = null;
        _currentUrl = null;
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [AudioPlayer] Error in playRadio: $e');
      debugPrint('📜 [AudioPlayer] Stack trace: $stackTrace');
      _currentStation = null;
      _currentUrl = null;
      rethrow;
    }
  }

  /// Pause the current playback
  Future<void> pause() async {
    try {
      if (_player.playing) {
        await _player.pause();
        log('Playback paused');
      }
    } catch (e) {
      log('Error pausing playback: $e');
      rethrow;
    }
  }

  /// Stop the current playback and reset state
  Future<void> stop() async {
    try {
      if (_currentUrl == null) {
        debugPrint('ℹ️ [AudioPlayer] No active playback to stop');
        return;
      }

      debugPrint('⏹️ [AudioPlayer] Stopping playback...');

      // Pause first to stop audio immediately
      await _player.pause();

      // Clear the audio source to prevent buffering
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse('')),
        preload: false,
      );

      // Reset player state
      await _player.stop();

      // Clear current state
      _currentStation = null;
      final stoppedUrl = _currentUrl;
      _currentUrl = null;

      debugPrint('⏹️ [AudioPlayer] Playback stopped for URL: $stoppedUrl');
    } catch (e) {
      debugPrint('❌ [AudioPlayer] Error stopping playback: $e');
      _currentStation = null;
      _currentUrl = null;
      rethrow;
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    try {
      await _player.dispose();
      log('Audio player disposed');
    } catch (e) {
      log('Error disposing audio player: $e');
      rethrow;
    }
  }
}
