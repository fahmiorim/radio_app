// lib/screens/full_player.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

import 'package:radio_odan_app/audio/audio_player_manager.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';
import 'package:radio_odan_app/providers/radio_station_provider.dart';
import 'package:radio_odan_app/services/live_chat_service.dart';
import 'package:radio_odan_app/services/live_chat_socket_service.dart';
import 'package:radio_odan_app/providers/live_status_provider.dart';

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

  // DVR Progress Bar Variables
  static const Duration _dvrWindowDuration = Duration(
    minutes: 30,
  ); // 30 menit sliding window
  Duration _dvrEndTime = _dvrWindowDuration;
  bool _showGoLiveButton = false;

  late final LiveStatusProvider _statusProvider;
  final Random _random = Random();
  final List<IconData> _reactions = [
    Icons.favorite,
    Icons.thumb_up,
    Icons.star,
    Icons.emoji_emotions,
  ];

  // Room yang saat ini disubscribe untuk like
  int? _subscribedRoomId;

  // Flag untuk mencegah aksi ganda
  bool _busyToggle = false;
  bool _showLikeAnimation = false;

  // Animasi floating emoji
  Widget _buildFloatingEmoji() {
    if (!_showLikeAnimation) return const SizedBox.shrink();

    final icon = _reactions[_random.nextInt(_reactions.length)];
    final size = 20.0 + _random.nextDouble() * 30.0;
    final duration = Duration(milliseconds: 1000 + _random.nextInt(1000));
    final offsetX = -20.0 + _random.nextDouble() * 40.0;

    return Positioned(
      bottom: 20,
      right: 0,
      left: 0,
      child: Center(
        child: Icon(icon, color: Colors.red, size: size)
            .animate(
              onComplete: (controller) {
                if (mounted) {
                  setState(() => _showLikeAnimation = false);
                }
              },
            )
            .slide(
              begin: const Offset(0, 0),
              end: Offset(offsetX / 50, -2.0),
              duration: duration,
              curve: Curves.easeOut,
            )
            .fadeOut(duration: duration),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Initialize player without loading state
    _initializePlayerAsync();

    _setupSocketListeners();

    // Initialize status provider but don't wait for it to avoid blocking
    _statusProvider = Provider.of<LiveStatusProvider>(context, listen: false);
    _statusProvider.addListener(_handleStatusChange);

    // Refresh status in background
    Future.microtask(() => _statusProvider.refresh());
  }

  // ====== Helpers UI ======
  Widget _buildDefaultCover() {
    return Image.asset(
      'assets/odanlogo.png',
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, _, _) => Icon(
        Icons.music_note,
        size: 100,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  String _clean(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty || t.toLowerCase() == 'null') return '';
    return t;
  }

  // ====== Socket listeners setup ======
  Future<void> _setupSocketListeners() async {
    try {
      // Ensure socket connection is established for live status updates
      // Add timeout to prevent hanging
      await LiveChatSocketService.I.ensureConnected().timeout(
        Duration(seconds: 10),
      );
    } catch (e) {
      // Socket connection is handled by LiveStatusProvider, continue silently
      // but log the error for debugging
    }
  }

  // ====== Init audio (async without loading state) ======
  Future<void> _initializePlayerAsync() async {
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
      // Silently handle errors since we're not showing loading state
    }
  }

  // ====== Live status handling ======
  void _handleStatusChange() {
    final isLive = _statusProvider.isLive;
    final roomId = _statusProvider.roomId;

    if (!isLive) {
      _onLiveEnded();
      return;
    }

    if (roomId != null && roomId != _liveRoomId) {
      _onLiveStarted(roomId);
    } else if (isLive && !_isLive) {
      setState(() => _isLive = true);
    }
  }

  Future<void> _onLiveStarted(int roomId) async {
    await _unsubscribeFromLikeUpdates();
    setState(() {
      _isLive = true;
      _liveRoomId = roomId;
      _likeCount = 0;
      _liked = false;
    });
    await _loadLikeStatus();
    await _subscribeToLikeUpdates(roomId);
  }

  // Subscribe to like updates
  Future<void> _subscribeToLikeUpdates(int roomId) async {
    try {
      await LiveChatSocketService.I.subscribeLike(
        roomId: roomId,
        onUpdated: (likeCount) {
          if (mounted) {
            setState(() {
              _likeCount = likeCount;
            });
          }
        },
      );
      _subscribedRoomId = roomId;
    } catch (e) {
      // Handle subscription error silently or log it
    }
  }

  void _onLiveEnded() {
    _unsubscribeFromLikeUpdates();
    if (mounted) {
      setState(() {
        _isLive = false;
        _liveRoomId = null;
        _likeCount = 0;
        _liked = false;
      });
    }
  }

  Future<void> _loadLikeStatus() async {
    try {
      final status = await LiveChatService.I.fetchGlobalStatus();
      if (mounted) {
        setState(() {
          _likeCount = status.likes < 0 ? 0 : status.likes;
          _liked = status.liked;
        });
      }
    } catch (_) {}
  }

  // ====== Refresh like status ======
  Future<void> _refreshLikeStatus() async {
    if (_liveRoomId == null) return;

    try {
      final status = await LiveChatService.I.fetchGlobalStatus();
      if (mounted) {
        setState(() {
          _liked = status.liked;
          _likeCount = status.likes < 0 ? 0 : status.likes;
        });
      }
    } catch (e) {
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

  // DVR Progress Bar Methods
  void _updateDvrWindow() {
    final currentPosition = _audioManager.player.position;
    setState(() {
      _dvrEndTime = currentPosition;
      _showGoLiveButton =
          currentPosition < (_dvrEndTime - const Duration(seconds: 5));
    });
  }

  Future<void> _seekToPosition(Duration position) async {
    try {
      await _audioManager.player.seek(position);
      _updateDvrWindow();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal melakukan seek')));
      }
    }
  }

  Future<void> _goLive() async {
    try {
      await _audioManager.player.seek(_dvrEndTime);
      setState(() {
        _showGoLiveButton = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal kembali ke live')));
      }
    }
  }

  // Unsubscribe from like updates
  Future<void> _unsubscribeFromLikeUpdates() async {
    if (_subscribedRoomId != null) {
      try {
        await LiveChatSocketService.I.unsubscribeLike(_subscribedRoomId!);
      } finally {
        _subscribedRoomId = null;
      }
    }
  }

  // Format number to K/M
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // ====== Toggle like ======
  Future<void> _toggleLike() async {
    if (_liveRoomId == null || _busyToggle) return;
    _busyToggle = true;

    final prevLiked = _liked;
    final prevCount = _likeCount;

    try {
      // Optimistic UI
      if (mounted) {
        setState(() {
          _liked = !prevLiked;
          final next = _liked
              ? prevCount + 1
              : (prevCount > 0 ? prevCount - 1 : 0);
          _likeCount = next < 0 ? 0 : next;
        });
      }

      final result = await LiveChatService.I.toggleLike(_liveRoomId!);
      if (result.isNotEmpty && mounted) {
        setState(() {
          _liked = result['liked'] == true;
          _likeCount = (result['likes'] as int?) ?? _likeCount;
        });
      } else {
        // Fallback to refresh if no result
        await _refreshLikeStatus();
      }

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      // Revert jika gagal
      setState(() {
        _liked = prevLiked;
        _likeCount = prevCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengupdate like. Coba lagi nanti.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        _busyToggle = false;
      }
    }
  }

  @override
  void dispose() {
    _statusProvider.removeListener(_handleStatusChange);
    _unsubscribeFromLikeUpdates();
    super.dispose();
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radioProvider = Provider.of<RadioStationProvider>(
      context,
    ); // RadioStationProvider
    final currentStation = radioProvider.currentStation;

    final nowPlaying = radioProvider.nowPlaying;
    final cover = _clean(nowPlaying?.artUrl);
    final title = _clean(nowPlaying?.title);
    final artist = _clean(nowPlaying?.artist);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Now Playing'),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Column(
              children: [
                // === Cover ===
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
                                errorWidget: (context, _, _) =>
                                    _buildDefaultCover(),
                              )
                            : _buildDefaultCover(),
                      ),
                    ),
                  ),
                ),

                // === Title / Artist / LIVE ===
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
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
                      if (_isLive)
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

                // === DVR Progress Bar (YouTube Live Style) ===
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      // DVR Progress Bar
                      SizedBox(
                        height: 20,
                        child: StreamBuilder<Duration>(
                          stream: _audioManager.player.positionStream,
                          builder: (context, snapshot) {
                            final currentPosition =
                                snapshot.data ?? Duration.zero;

                            // Update DVR window based on current position
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _updateDvrWindow();
                            });

                            return ProgressBar(
                              progress: currentPosition,
                              total: _dvrEndTime,
                              buffered:
                                  currentPosition, // For live streams, buffered = current position
                              onSeek: _seekToPosition,
                              progressBarColor: theme.colorScheme.primary,
                              baseBarColor: theme.colorScheme.onSurface
                                  .withAlpha(30),
                              bufferedBarColor: theme.colorScheme.primary
                                  .withAlpha(100),
                              thumbColor: theme.colorScheme.primary,
                              thumbGlowColor: theme.colorScheme.primary
                                  .withAlpha(100),
                              timeLabelLocation: TimeLabelLocation.sides,
                              timeLabelType: TimeLabelType.totalTime,
                              timeLabelTextStyle: theme.textTheme.bodySmall
                                  ?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontFeatures: [
                                      const FontFeature.tabularFigures(),
                                    ],
                                  ),
                              barHeight: 4,
                              thumbRadius: 8,
                              timeLabelPadding: 8,
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Go Live Button (YouTube Live Style)
                      if (_showGoLiveButton)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _goLive,
                            icon: Icon(
                              Icons.play_arrow,
                              color: _isLive
                                  ? Colors.white
                                  : theme.colorScheme.onPrimary,
                            ),
                            label: Text(
                              'LIVE',
                              style: TextStyle(
                                color: _isLive
                                    ? Colors.white
                                    : theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: _isLive
                                  ? theme.colorScheme.onError
                                  : theme.colorScheme.onSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // === Controls ===
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
                            // Heart (Like)
                            // Modern Like Button with Count
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Like Button
                                GestureDetector(
                                  onTap: _isLive && !_busyToggle
                                      ? () async {
                                          await _toggleLike();
                                          if (_liked) {
                                            setState(
                                              () => _showLikeAnimation = true,
                                            );
                                          }
                                        }
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isLive
                                          ? (_liked
                                                ? Colors.red.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : theme
                                                      .colorScheme
                                                      .surfaceContainerHighest)
                                          : theme
                                                .colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _isLive
                                            ? (_liked
                                                  ? Colors.red
                                                  : theme.colorScheme.outline
                                                        .withValues(alpha: 0.5))
                                            : theme.colorScheme.outline
                                                  .withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _liked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: _isLive
                                              ? (_liked
                                                    ? Colors.red
                                                    : theme
                                                          .colorScheme
                                                          .onSurfaceVariant)
                                              : theme.disabledColor,
                                          size: 20,
                                        ),
                                        if (_likeCount > 0) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatCount(_likeCount),
                                            style: TextStyle(
                                              color: _isLive
                                                  ? (_liked
                                                        ? Colors.red
                                                        : theme
                                                              .colorScheme
                                                              .onSurfaceVariant)
                                                  : theme.disabledColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                // Like animation
                                if (_showLikeAnimation) _buildFloatingEmoji(),
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
                              onPressed: currentStation != null
                                  ? () async {
                                      final s = currentStation;
                                      await Share.share(
                                        '🎵 Listening to "${s.title}" on ${s.host}\n\n${s.streamUrl}',
                                      );
                                    }
                                  : null,
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
