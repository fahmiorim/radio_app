import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/audio/audio_player_manager.dart';
import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/providers/radio_station_provider.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final AudioPlayerManager _audioManager = AudioPlayerManager.instance;

  Widget _buildDefaultCover() {
    return Image.asset(
      'assets/odanlogo.png',
      width: 42,
      height: 42,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.music_note,
        size: 24,
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withOpacity(0.7),
      ),
    );
  }

  @override
  void dispose() {
    // Don't dispose the audio manager here as it's a singleton
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radioProvider = Provider.of<RadioStationProvider>(context);
    final currentStation =
        radioProvider.currentStation ?? RadioStationProvider.defaultStation;
    final nowPlaying = radioProvider.nowPlaying;

    final artUrl = nowPlaying?.artUrl;
    final cover = (artUrl != null && artUrl.isNotEmpty)
        ? artUrl
        : currentStation.coverUrl;
    final nowTitle = nowPlaying?.title;
    final title = (nowTitle != null && nowTitle.isNotEmpty)
        ? nowTitle
        : currentStation.title;
    final nowArtist = nowPlaying?.artist;
    final artist = (nowArtist != null && nowArtist.isNotEmpty)
        ? nowArtist
        : currentStation.host;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Use pushNamed to navigate to the full player screen
        Navigator.of(context).pushNamed(AppRoutes.fullPlayer);
      },
        child: Container(
          height: 55,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .shadow
                    .withOpacity(0.2),
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
                    child: (nowPlaying != null && nowPlaying.artUrl.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: cover,
                            height: 42,
                            width: 42,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                _buildDefaultCover(),
                          )
                        : _buildDefaultCover(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        artist,
                        style: Theme.of(context).textTheme.bodySmall,
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
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "LIVE",
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onError,
                                    fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),

                      /// StreamBuilder untuk pantau state player
                      StreamBuilder<PlayerState>(
                        stream: _audioManager.player.playerStateStream,
                        builder: (context, snapshot) {
                          final state = snapshot.data;
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
                              radioProvider.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                            ),
                            onPressed: () async {
                              await radioProvider.togglePlayPause();
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
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
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
