import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../audio/audio_player_manager.dart';
import '../config/app_routes.dart';
import '../providers/radio_station_provider.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final AudioPlayerManager _audioManager = AudioPlayerManager();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    // Listen to player state changes
    _audioManager.player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    // Don't dispose the audio manager here as it's a singleton
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radioProvider = Provider.of<RadioStationProvider>(context);
    final currentStation = radioProvider.currentStation ?? RadioStationProvider.defaultStation;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Gunakan navigator dengan pushReplacementNamed untuk mencegah penumpukan route
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.fullPlayer,
        );
      },
      child: Container(
        height: 55,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xF3200C18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      currentStation.coverUrl,
                      height: 42,
                      width: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentStation.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentStation.host,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  /// === LIVE + Play Button ===
                  Row(
                    children: [
                      // Tulisan LIVE
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "LIVE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      /// StreamBuilder untuk pantau state player
                      StreamBuilder<PlayerState>(
                        stream: _audioManager.player.playerStateStream,
                        builder: (context, snapshot) {
                          final state = snapshot.data;
                          final isBuffering = state?.processingState ==
                                  ProcessingState.loading ||
                              state?.processingState ==
                                  ProcessingState.buffering;

                          if (isBuffering) {
                            return const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }

                          return IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              if (_isPlaying) {
                                await _audioManager.pause();
                              } else {
                                await _audioManager.playRadio(currentStation);
                              }
                              if (mounted) {
                                radioProvider.setPlaying(!_isPlaying);
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// progress bar tipis
            StreamBuilder<Duration>(
              stream: _audioManager.player.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                final duration =
                    _audioManager.player.duration ?? const Duration(seconds: 1);
                double progress = duration.inMilliseconds > 0 
                    ? pos.inMilliseconds / duration.inMilliseconds 
                    : 0.0;

                return SizedBox(
                  height: 2, // ketebalan bar
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
