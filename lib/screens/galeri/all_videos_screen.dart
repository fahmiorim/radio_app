import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/video_model.dart';
import '../../providers/video_provider.dart';
import '../../widgets/app_bar.dart';
import '../../config/app_colors.dart';

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
    final shouldRefresh = _lastVideos == null ||
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
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: CustomAppBar.transparent(title: 'Semua Video'),
      body: Stack(
        children: [
          // Background gradient + bubble
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, AppColors.backgroundDark],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(top: -50, right: -50, child: _bubble(200)),
                  Positioned(bottom: -30, left: -30, child: _bubble(150)),
                  Positioned(top: 100, left: 100, child: _bubble(80)),
                ],
              ),
            ),
          ),

          // Content
          Positioned.fill(
            child: Consumer<VideoProvider>(
              builder: (context, vp, _) {
                return RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _onRefresh,
                  color: AppColors.primary,
                  child: _buildVideoList(vp),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.05),
      ),
    );
  }

  Widget _buildVideoList(VideoProvider vp) {
    if (vp.isLoadingAll && vp.allVideos.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (vp.hasErrorAll && vp.allVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              vp.errorMessageAll,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => vp.fetchAllVideos(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final itemCount = vp.allVideos.length + (vp.hasMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= vp.allVideos.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        final video = vp.allVideos[index];
        return _buildVideoItem(video);
      },
    );
  }

  Widget _buildVideoItem(VideoModel video) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withOpacity(0.1),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            video.safeThumbnailUrl,
            width: 100,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 100,
              height: 60,
              color: Colors.grey[800],
              child: const Icon(Icons.videocam_off, color: Colors.white54),
            ),
          ),
        ),
        title: Text(
          video.title,
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(video.createdAt),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        onTap: () => _openYoutube(video.watchUrl),
        trailing: const Icon(Icons.play_circle_outline, color: Colors.white70),
      ),
    );
  }
}
