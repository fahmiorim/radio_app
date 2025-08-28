import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../../models/video_model.dart';
import '../../providers/video_provider.dart';
import '../../widgets/app_bar.dart';
import '../../config/app_colors.dart';

class AllVideosScreen extends StatefulWidget {
  const AllVideosScreen({Key? key}) : super(key: key);

  @override
  State<AllVideosScreen> createState() => _AllVideosScreenState();
}

class _AllVideosScreenState extends State<AllVideosScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialVideos();
    });
  }

  Future<void> _loadInitialVideos() async {
    final videoProvider = context.read<VideoProvider>();
    await videoProvider.fetchAllVideos();
  }

  Future<void> _onRefresh() async {
    final videoProvider = context.read<VideoProvider>();
    videoProvider.resetPagination();
    await videoProvider.fetchAllVideos();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      final videoProvider = context.read<VideoProvider>();
      if (!videoProvider.isLoadingAll && videoProvider.hasMore) {
        _isLoadingMore = true;
        videoProvider.fetchAllVideos(loadMore: true).whenComplete(() {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  Future<void> _openYoutubeVideo(String? url) async {
    if (url == null || url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka video')),
        );
      }
    }
  }

  String _formatDate(dynamic dateValue) {
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue).toLocal();
      } else if (dateValue is DateTime) {
        date = dateValue.toLocal();
      } else {
        return '';
      }
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: CustomAppBar.transparent(title: 'Semua Video'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Background with gradient and bubbles
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
                      // Large bubble top right
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      // Medium bubble bottom left
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      // Small bubble center
                      Positioned(
                        top: 100,
                        left: 100,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              Positioned.fill(
                child: Consumer<VideoProvider>(
                  builder: (context, videoProvider, _) {
                    return RefreshIndicator(
                      key: _refreshIndicatorKey,
                      onRefresh: _onRefresh,
                      color: AppColors.primary,
                      child: _buildVideoList(videoProvider),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoList(VideoProvider videoProvider) {
    if (videoProvider.isLoadingAll && videoProvider.allVideos.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (videoProvider.hasErrorAll && videoProvider.allVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              videoProvider.errorMessageAll,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => videoProvider.fetchAllVideos(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount:
          videoProvider.allVideos.length + (videoProvider.isLoadingAll ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= videoProvider.allVideos.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        final video = videoProvider.allVideos[index];
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
            video.thumbnailUrl ?? '',
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
        onTap: () => _openYoutubeVideo(video.youtubeUrl),
        trailing: const Icon(Icons.play_circle_outline, color: Colors.white70),
      ),
    );
  }
}
