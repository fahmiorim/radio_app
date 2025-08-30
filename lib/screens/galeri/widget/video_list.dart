import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';

import '../../../config/app_routes.dart';
import '../../../models/video_model.dart';
import '../../../providers/video_provider.dart';
import '../../../widgets/skeleton/video_list_skeleton.dart';
import '../../../widgets/section_title.dart';

class VideoList extends StatefulWidget {
  const VideoList({super.key});

  @override
  State<VideoList> createState() => _VideoListState();
}

class _VideoListState extends State<VideoList>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  bool _isMounted = false;
  List<VideoModel>? _lastVideos;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _loadData() async {
    final provider = context.read<VideoProvider>();
    await provider.fetchRecentVideos();
    _lastVideos = List<VideoModel>.from(provider.recentVideos);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndRefresh();
      }
    });
  }

  Future<void> _checkAndRefresh() async {
    if (!mounted) return;

    final provider = context.read<VideoProvider>();
    final current = provider.recentVideos;
    final shouldRefresh = _lastVideos == null ||
        !const DeepCollectionEquality().equals(_lastVideos, current);

    if (shouldRefresh) {
      await provider.fetchRecentVideos(forceRefresh: true);
      if (mounted) {
        setState(() {
          _lastVideos = List<VideoModel>.from(provider.recentVideos);
        });
      }
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isMounted) {
      _checkAndRefresh();
    }
  }

  Future<void> _openYoutubeVideo(VideoModel video) async {
    final url = (video.youtubeUrl.isNotEmpty)
        ? video.youtubeUrl
        : (video.youtubeId.isNotEmpty
              ? 'https://www.youtube.com/watch?v=${video.youtubeId}'
              : '');

    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link video tidak tersedia')),
        );
      }
      return;
    }

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

  String _thumbUrl(VideoModel v) {
    if (v.thumbnailUrl.isNotEmpty) return v.thumbnailUrl;
    if (v.youtubeId.isNotEmpty) {
      return 'https://img.youtube.com/vi/${v.youtubeId}/hqdefault.jpg';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, _) {
        final isLoading = videoProvider.isLoadingRecent;
        final hasError = videoProvider.hasErrorRecent;
        final errMsg = videoProvider.errorMessageRecent;
        final items = videoProvider.recentVideos;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Video',
              onSeeAll: items.isNotEmpty
                  ? () => Navigator.pushNamed(context, AppRoutes.allVideos)
                  : null,
            ),
            SizedBox(
              height: 280,
              child: isLoading
                  ? const VideoListSkeleton()
                  : hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(errMsg, textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: context
                                .read<VideoProvider>()
                                .fetchRecentVideos,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
                  : items.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada video tersedia',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final video = items[index];
                        final thumbnailUrl = _thumbUrl(video);

                        return InkWell(
                          onTap: () => _openYoutubeVideo(video),
                          child: SizedBox(
                            width: 320,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: thumbnailUrl.isNotEmpty
                                          ? Image.network(
                                              thumbnailUrl,
                                              width: 320,
                                              height: 180,
                                              fit: BoxFit.cover,
                                              loadingBuilder:
                                                  (context, child, progress) {
                                                    if (progress == null) {
                                                      return child;
                                                    }
                                                    return const SizedBox(
                                                      width: 320,
                                                      height: 180,
                                                      child: Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    );
                                                  },
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const SizedBox(
                                                    width: 320,
                                                    height: 180,
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 40,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ),
                                            )
                                          : const SizedBox(
                                              width: 320,
                                              height: 180,
                                              child: Center(
                                                child: Icon(
                                                  Icons.videocam_off,
                                                  size: 40,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ),
                                    ),
                                    const Positioned.fill(
                                      child: Center(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  video.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
