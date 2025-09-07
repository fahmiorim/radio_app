import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:radio_odan_app/models/video_model.dart';
import 'package:radio_odan_app/providers/video_provider.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';
import 'package:radio_odan_app/widgets/common/mini_player.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';

class AllVideosScreen extends StatefulWidget {
  const AllVideosScreen({Key? key}) : super(key: key);

  @override
  State<AllVideosScreen> createState() => _AllVideosScreenState();
}

class _AllVideosScreenState extends State<AllVideosScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _isLoadingMore = false;
  bool _isMounted = false;
  List<VideoModel>? _lastVideos;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addObserver(this);

    _scrollController.addListener(_onScroll);

    // Load awal setelah frame pertama agar aman untuk akses context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialVideos();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tunda ke frame berikutnya agar aman jika memicu setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_checkAndRefresh());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isMounted) {
      unawaited(_checkAndRefresh());
    }
  }

  Future<void> _loadInitialVideos() async {
    final videoProvider = context.read<VideoProvider>();
    await videoProvider.fetchAllVideos();
    _lastVideos = List<VideoModel>.from(videoProvider.allVideos);
  }

  Future<void> _onRefresh() async {
    final videoProvider = context.read<VideoProvider>();
    videoProvider.resetPagination();
    await videoProvider.fetchAllVideos();
    _lastVideos = List<VideoModel>.from(videoProvider.allVideos);
  }

  Future<void> _checkAndRefresh() async {
    if (!mounted) return;

    final vp = context.read<VideoProvider>();
    final currentVideos = vp.allVideos;
    final shouldRefresh =
        _lastVideos == null ||
        !const DeepCollectionEquality().equals(_lastVideos, currentVideos);

    if (shouldRefresh) {
      vp.resetPagination();
      await vp.fetchAllVideos();
      if (mounted) {
        setState(() {
          _lastVideos = List<VideoModel>.from(vp.allVideos);
        });
      }
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final vp = context.read<VideoProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !vp.isLoadingAll &&
        vp.hasMore) {
      _isLoadingMore = true;
      vp.fetchAllVideos(loadMore: true).whenComplete(() {
        if (mounted) {
          setState(() => _isLoadingMore = false);
        }
      });
    }
  }

  Future<void> _openYoutube(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka video')),
      );
    }
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy', 'id_ID').format(date.toLocal());
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: CustomAppBar(
        title: 'Semua Video',
        titleColor: colors.onBackground,
        iconColor: colors.onBackground,
      ),
      body: Stack(
        children: [
            const AppBackground(),

            // Content
            Positioned.fill(
            child: Consumer<VideoProvider>(
              builder: (context, vp, _) {
                return RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _onRefresh,
                  color: colors.primary,
                  child: _buildVideoList(vp),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
  Widget _buildLoadingSkeleton() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 60,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 200,
                      color: colors.surfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 150,
                      color: colors.surfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoList(VideoProvider vp) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (vp.isLoadingAll && vp.allVideos.isEmpty) {
      return _buildLoadingSkeleton();
    }

    if (vp.hasErrorAll && vp.allVideos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.error),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat video',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                vp.errorMessageAll,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _onRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (vp.allVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 64,
              color: colors.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada video yang tersedia',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cek kembali nanti untuk video terbaru',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      itemCount: vp.allVideos.length + (vp.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= vp.allVideos.length) {
          return _isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox();
        }
        final video = vp.allVideos[index];
        return _buildVideoItem(video);
      },
    );
  }

  Widget _buildVideoItem(VideoModel video) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: colors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colors.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _openYoutube(video.watchUrl),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  video.safeThumbnailUrl,
                  width: 100,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100,
                    height: 60,
                    color: colors.surfaceVariant,
                    child: Icon(
                      Icons.videocam_off_outlined,
                      color: colors.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 100,
                      height: 60,
                      color: colors.surfaceVariant,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Video info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(video.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Play button
              Icon(
                Icons.play_circle_outline_rounded,
                color: colors.primary,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
