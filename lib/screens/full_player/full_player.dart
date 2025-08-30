import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../audio/audio_player_manager.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/radio_station_provider.dart';

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
          const Icon(Icons.music_note, size: 100, color: Colors.white),
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

    final cover = (nowPlaying?.artUrl.isNotEmpty ?? false)
        ? nowPlaying!.artUrl
        : currentStation?.coverUrl ?? '';
    final title = (nowPlaying?.title.isNotEmpty ?? false)
        ? nowPlaying!.title
        : currentStation?.title ?? '';
    final artist = (nowPlaying?.artist.isNotEmpty ?? false)
        ? nowPlaying!.artist
        : currentStation?.host ?? '';

    if (currentStation == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Text(
            'No radio station selected',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          "Now Playing",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white),
          onPressed: () {
            // Update the provider state before navigating back
            if (mounted) {
              Navigator.pop(context);
            }
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
                    child: (nowPlaying != null && nowPlaying.artUrl.isNotEmpty)
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "LIVE",
                      style: TextStyle(
                        fontSize: 12,
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
                  final duration =
                      _audioManager.player.duration ??
                      const Duration(seconds: 1);
                  double progress =
                      pos.inMilliseconds / duration.inMilliseconds;
                  if (progress.isNaN) progress = 0.0;

                  return Column(
                    children: [
                      SizedBox(
                        height: 4,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withAlpha(30),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.red,
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
                        IconButton(
                          icon: Icon(
                            isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorited
                                ? const Color(0xFF1DB954)
                                : Colors.grey,
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
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: isFavorited
                                    ? const Color(0xFF1DB954)
                                    : Colors.grey,
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF121212),
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  iconSize: 40,
                                  color: const Color(0xFF121212),
                                  icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                  ),
                                  onPressed: () async {
                                    await radioProvider.togglePlayPause();
                                  },
                                ),
                        ),
                        const SizedBox(width: 25),

                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.grey),
                          iconSize: 28,
                          onPressed: () async {
                            await Share.share(
                              '🎵 Listening to "${currentStation.title}" on ${currentStation.host}\n\n${currentStation.streamUrl}',
                              subject: 'Listen to ${currentStation.title}',
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
