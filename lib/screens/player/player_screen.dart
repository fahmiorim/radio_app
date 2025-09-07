import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/audio/audio_player_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:radio_odan_app/providers/radio_station_provider.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';

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
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.music_note,
        size: 100,
        color: Theme.of(context).colorScheme.onSurface,
      ),
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
    final theme = Theme.of(context);
    final radioProvider = Provider.of<RadioStationProvider>(context);
    final currentStation = radioProvider.currentStation;
    final nowPlaying = radioProvider.nowPlaying;

      if (currentStation == null) {
        return Scaffold(
          body: Stack(
            children: [
              const AppBackground(showSmallBubble: true),
              Center(
                child: Text(
                  'No radio station selected',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }

    final cover = nowPlaying?.artUrl?.isNotEmpty == true
        ? nowPlaying!.artUrl
        : (currentStation.coverUrl ?? '');

    final title = nowPlaying?.title?.isNotEmpty == true
        ? nowPlaying!.title
        : (currentStation.title ?? 'Unknown Title');

    final artist = nowPlaying?.artist?.isNotEmpty == true
        ? nowPlaying!.artist
        : (currentStation.host ?? 'Unknown');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Now Playing',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () {
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          const AppBackground(showSmallBubble: true),
          SafeArea(
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
                    style: theme.textTheme.titleLarge?.copyWith(
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
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
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
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'LIVE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onError,
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
                          backgroundColor:
                              theme.colorScheme.onSurface.withAlpha(30),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
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
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.onSurfaceVariant,
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
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isFavorited
                                        ? theme.colorScheme.onSecondary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                backgroundColor: isFavorited
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.onSurfaceVariant,
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
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: theme.colorScheme.onPrimary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  iconSize: 40,
                                  color: theme.colorScheme.onPrimary,
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
                          icon: Icon(
                            Icons.share,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
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
      ],
    ),
    );
  }
}
