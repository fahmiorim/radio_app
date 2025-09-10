// lib/screens/full_player.dart
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

  late final LiveStatusProvider _statusProvider;

  // Flag untuk mencegah aksi ganda
  bool _busyToggle = false;
  bool _showLikeAnimation = false;
  final Random _random = Random();
  final List<IconData> _reactions = [
    Icons.favorite,
    Icons.thumb_up,
    Icons.star,
    Icons.emoji_emotions,
  ];

  // Room yang saat ini disubscribe untuk like
  int? _subscribedRoomId;

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
    _initializePlayer();
    _setupSocketListeners();
    _statusProvider = Provider.of<LiveStatusProvider>(context, listen: false);
    _statusProvider.addListener(_handleStatusChange);
    _handleStatusChange();
    _statusProvider.refresh();
  }

  // ====== Helpers UI ======
  Widget _buildDefaultCover() {
    return Image.asset(
      'assets/odanlogo.png',
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, _, __) => Icon(
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

  // ====== Init audio ======
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memutar radio. Coba lagi nanti.')),
      );
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

  // ====== WebSocket Handlers ======
  void _setupSocketListeners() {
    // No need for direct callback setup as we'll use subscribeLike with callback
  }

  // Subscribe to like updates for a room
  Future<void> _subscribeToLikeUpdates(int roomId) async {
    if (_subscribedRoomId == roomId) return;

    // Unsubscribe from previous room if any
    await _unsubscribeFromLikeUpdates();

    try {
      await LiveChatSocketService.I.subscribeLike(
        roomId: roomId,
        onUpdated: (count) {
          if (mounted) {
            setState(() {
              _likeCount = count < 0 ? 0 : count;
            });
          }
        },
      );
      _subscribedRoomId = roomId;
    } catch (e) {}
  }

  // Unsubscribe from like updates
  Future<void> _unsubscribeFromLikeUpdates() async {
    if (_subscribedRoomId != null) {
      try {
        await LiveChatSocketService.I.unsubscribeLike(_subscribedRoomId!);
      } catch (e) {
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
                                errorWidget: (context, _, __) =>
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

                // === Progress Bar ===
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  child: StreamBuilder<Duration>(
                    stream: _audioManager.player.positionStream,
                    builder: (context, snapshot) {
                      final pos = snapshot.data ?? Duration.zero;
                      final duration = _audioManager.player.duration;

                      // Radio live → duration null/0 = indeterminate
                      final isIndeterminate =
                          duration == null || duration.inMilliseconds <= 0;
                      double? progress;
                      if (!isIndeterminate) {
                        final denom = duration.inMilliseconds == 0
                            ? 1
                            : duration.inMilliseconds;
                        progress = (pos.inMilliseconds / denom)
                            .clamp(0.0, 1.0)
                            .toDouble();
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
                                                ? Colors.red.withOpacity(0.1)
                                                : theme
                                                      .colorScheme
                                                      .surfaceVariant)
                                          : theme.colorScheme.surfaceVariant
                                                .withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _isLive
                                            ? (_liked
                                                  ? Colors.red
                                                  : theme.colorScheme.outline
                                                        .withOpacity(0.5))
                                            : theme.colorScheme.outline
                                                  .withOpacity(0.3),
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
