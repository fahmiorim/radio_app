import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/audio/audio_player_manager.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';
import 'package:share_plus/share_plus.dart';
import 'package:radio_odan_app/providers/radio_station_provider.dart';
import 'package:radio_odan_app/services/live_chat_service.dart';
import 'package:radio_odan_app/services/live_chat_socket_service.dart';

class FullPlayer extends StatefulWidget {
  const FullPlayer({super.key});

  @override
  State<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends State<FullPlayer> {
  final _audioManager = AudioPlayerManager.instance;

  int _likeCount = 0;
  bool _liked = false;
  bool _isLive = false;
  int? _liveRoomId;

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
    _initLike();
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

  Future<void> _initLike() async {
    try {
      debugPrint('🔄 Fetching initial like status...');
      
      // First, ensure WebSocket is connected
      try {
        await LiveChatSocketService.I.ensureConnected();
        debugPrint('✅ WebSocket connection established');
      } catch (e) {
        debugPrint('⚠️ Could not establish WebSocket connection: $e');
      }
      
      // Then fetch the current status
      final status = await LiveChatService.I.fetchGlobalStatus();
      debugPrint('📊 Initial status: isLive=${status.isLive}, likes=${status.likes}, liked=${status.liked}, roomId=${status.roomId}');
      
      if (mounted) {
        setState(() {
          _isLive = status.isLive;
          _likeCount = status.likes;
          _liked = status.liked;
          _liveRoomId = status.roomId;
        });

        if (_isLive && _liveRoomId != null) {
          debugPrint('🔌 Subscribing to like updates for room $_liveRoomId');
          
          // Add a small delay to ensure WebSocket is ready
          await Future.delayed(const Duration(milliseconds: 500));
          
          try {
            await LiveChatSocketService.I.subscribeLike(
              roomId: _liveRoomId!,
              onUpdated: (count) {
                debugPrint('❤️ Received like update: $count');
                if (mounted) {
                  setState(() {
                    _likeCount = count;
                    // Don't update _liked here as we only get count updates
                  });
                }
              },
            );
            debugPrint('✅ Successfully subscribed to like updates');
          } catch (e) {
            debugPrint('❌ Error subscribing to like updates: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tidak dapat terhubung ke pembaruan like.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } else {
          debugPrint('ℹ️ Not live or no room ID, skipping WebSocket subscription');
        }
      }
    } catch (e) {
      debugPrint('❌ Error initializing like status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat status like.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_liveRoomId == null) {
      debugPrint('❌ Cannot toggle like: liveRoomId is null');
      return;
    }
    
    try {
      debugPrint('🔄 Toggling like for room: $_liveRoomId');
      final res = await LiveChatService.I.toggleLike(_liveRoomId!);
      
      if (mounted) {
        setState(() {
          _liked = res['liked'] == true;
          _likeCount = (res['likes'] as int?) ?? _likeCount;
          debugPrint('✅ Like toggled: liked=$_liked, count=$_likeCount');
        });
      }
    } catch (e) {
      debugPrint('❌ Error toggling like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui like. Coba lagi nanti.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_liveRoomId != null) {
      LiveChatSocketService.I.unsubscribeLike(_liveRoomId!);
    }
    super.dispose();
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
            const AppBackground(),
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

    String clean(String? s) {
      final t = s?.trim();
      if (t == null || t.isEmpty || t.toLowerCase() == 'null') return '';
      return t;
    }

    final cover = clean(nowPlaying?.artUrl);
    final title = clean(nowPlaying?.title);
    final artist = clean(nowPlaying?.artist);

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
          const AppBackground(),
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                        ),
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

                      // Radio live → durasi null/0, pakai indeterminate
                      final isIndeterminate =
                          duration == null || duration.inMilliseconds <= 0;
                      double? progress;
                      if (!isIndeterminate) {
                        final denom = duration.inMilliseconds == 0
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
                              backgroundColor: theme.colorScheme.onSurface
                                  .withAlpha(30),
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

                // === Player Controls (Heart = Like) ===
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
                            // HEART = LIKE
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _liked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                  ),
                                  color: _isLive
                                      ? (_liked
                                            ? const Color(0xFFDB2777)
                                            : theme
                                                  .colorScheme
                                                  .onSurfaceVariant)
                                      : theme.disabledColor,
                                  iconSize: 28,
                                  onPressed: _isLive ? _toggleLike : null,
                                  tooltip: _liked ? 'Batalkan Suka' : 'Suka',
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '$_likeCount',
                                  style: TextStyle(
                                    color: _isLive
                                        ? Colors.white70
                                        : theme.disabledColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
                                        isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                      ),
                                      onPressed: () async {
                                        await Provider.of<RadioStationProvider>(
                                          context,
                                          listen: false,
                                        ).togglePlayPause();
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
                                final s = currentStation;
                                await Share.share(
                                  '🎵 Listening to "${s.title}" on ${s.host}\n\n${s.streamUrl}',
                                  subject: 'Listen to ${s.title}',
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
