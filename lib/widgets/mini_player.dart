import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../data/dummy_radio.dart';
import '../audio/audio_player_manager.dart';
import '../config/app_routes.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final audioManager = AudioPlayerManager();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.fullPlayer);
      },
      child: Container(
        height: 55,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xF3200C18),
        ),

        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      dummyRadio.coverUrl,
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
                          dummyRadio.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          dummyRadio.host,
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
                        stream: audioManager.playerStateStream,
                        builder: (context, snapshot) {
                          final state = snapshot.data;
                          final isPlaying = state?.playing ?? false;
                          final isBuffering =
                              state?.processingState ==
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
                              isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            onPressed: () {
                              if (isPlaying) {
                                audioManager.pause();
                              } else {
                                audioManager.playRadio(
                                  dummyRadio,
                                ); // <-- pakai RadioStation
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
              stream: audioManager.player.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                final duration =
                    audioManager.player.duration ?? const Duration(seconds: 1);
                double progress = pos.inMilliseconds / duration.inMilliseconds;
                if (progress.isNaN) progress = 0.0;

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
