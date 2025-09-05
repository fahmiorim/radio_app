import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/audio/audio_player_manager.dart';
import 'package:radio_odan_app/config/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:radio_odan_app/providers/radio_station_provider.dart';

class FullPlayer extends StatefulWidget {
  const FullPlayer({super.key});

  @override
  State<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends State<FullPlayer> {
  final _audioManager = AudioPlayerManager.instance;
  bool isFavorited = false;

  Widget _buildDefaultCover() {
    return Image.asset(
      'assets/odanlogo.png',
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.music_note, size: 100, color: AppColors.white),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final radioProvider = Provider.of<RadioStationProvider>(
        context,
        listen: false,
      );
      final currentStation = radioProvider.currentStation;
      if (currentStation != null) {
        await _audioManager.playRadio(currentStation);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memutar radio. Coba lagi nanti.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final radioProvider = Provider.of<RadioStationProvider>(context);
    final currentStation = radioProvider.currentStation;
    final nowPlaying = radioProvider.nowPlaying;

    if (currentStation == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: Text(
            'No radio station selected',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final cover = (nowPlaying?.artUrl.isNotEmpty ?? false)
        ? nowPlaying!.artUrl
        : (currentStation.coverUrl ?? '');

    final title = (nowPlaying?.title.isNotEmpty ?? false)
        ? nowPlaying!.title
        : (currentStation.title ?? 'Unknown Title');

    final artist = (nowPlaying?.artist.isNotEmpty ?? false)
        ? nowPlaying!.artist
        : (currentStation.host ?? 'Unknown');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Now Playing',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.transparent,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: AppColors.white,
          ),
          onPressed: () {
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // === Cover image ===
            Expanded(
              flex: 5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: cover,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                _buildDefaultCover(),
                          )
                        : _buildDefaultCover(),
                  ),
                ),
              ),
            ),

            // === Title & Host & LIVE ===
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors().liveBadge,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'LIVE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // === Progress Bar ===
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 15,
              ),
              child: StreamBuilder<Duration>(
                stream: _audioManager.player.positionStream,
                builder: (context, snapshot) {
                  final pos = snapshot.data ?? Duration.zero;
                  final duration = _audioManager.player.duration;

                  // Jika durasi null (umum untuk radio live), jadikan indeterminate
                  final isIndeterminate =
                      duration == null || duration.inMilliseconds <= 0;
                  double? progress;
                  if (!isIndeterminate) {
                    final denom = duration!.inMilliseconds == 0
                        ? 1
                        : duration.inMilliseconds;
                    progress = (pos.inMilliseconds / denom).clamp(0.0, 1.0);
                    if (progress.isNaN) progress = 0.0;
                  }

                  return Column(
                    children: [
                      SizedBox(
                        height: 4,
                        child: LinearProgressIndicator(
                          value: isIndeterminate ? null : progress,
                          backgroundColor: AppColors.white.withAlpha(30),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),

            // === Player Control ===
            Expanded(
              flex: 2,
              child: Center(
                child: StreamBuilder<PlayerState>(
                  stream: _audioManager.player.playerStateStream,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    final isPlaying = state?.playing ?? false;
                    final processing = state?.processingState;
                    final isLoading =
                        processing == ProcessingState.loading ||
                        processing == ProcessingState.buffering;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Favorite
                        IconButton(
                          icon: Icon(
                            isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorited
                                ? AppColors.green
                                : AppColors.grey,
                          ),
                          iconSize: 28,
                          onPressed: () {
                            setState(() => isFavorited = !isFavorited);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFavorited
                                      ? 'Added to favorites'
                                      : 'Removed from favorites',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                                backgroundColor: isFavorited
                                    ? AppColors.green
                                    : AppColors.grey,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 25),

                        // Play / Pause
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.player.controls,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  iconSize: 40,
                                  color: AppColors.white,
                                  icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                  ),
                                  onPressed: () async {
                                    await radioProvider.togglePlayPause();
                                  },
                                ),
                        ),
                        const SizedBox(width: 25),

                        // Share
                        IconButton(
                          icon: const Icon(Icons.share, color: AppColors.grey),
                          iconSize: 28,
                          onPressed: () async {
                            final sTitle = currentStation.title ?? 'ODAN FM';
                            final sHost = currentStation.host ?? 'ODAN FM';
                            final sUrl = currentStation.streamUrl ?? '';
                            await Share.share(
                              '🎵 Listening to "$sTitle" on $sHost\n\n$sUrl',
                              subject: 'Listen to $sTitle',
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
