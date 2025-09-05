import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';

import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/config/app_colors.dart';
import 'package:radio_odan_app/models/video_model.dart';
import 'package:radio_odan_app/providers/video_provider.dart';
import 'package:radio_odan_app/widgets/skeleton/video_list_skeleton.dart';
import 'package:radio_odan_app/widgets/common/section_title.dart';

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

    WidgetsBinding.instance.addObserver(this);

    // Jalankan setelah frame pertama agar aman akses context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    final provider = context.read<VideoProvider>();
    await provider.fetchRecentVideos(forceRefresh: forceRefresh);
    if (mounted) {
      setState(() {
        _lastVideos = List<VideoModel>.from(provider.recentVideos);
      });
    }
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
    final shouldRefresh =
        _lastVideos == null ||
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isMounted) {
      // Tunda ke frame berikutnya agar aman terhadap setState saat build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkAndRefresh();
      });
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _openYoutubeVideo(VideoModel video) async {
    final url = Uri.parse('https://www.youtube.com/watch?v=${video.youtubeId}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
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

        final colorScheme = Theme.of(context).colorScheme;
        final isDark = colorScheme.brightness == Brightness.dark;
        final textPrimaryColor =
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final textSecondaryColor =
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        final overlayColor = colorScheme.surface.withOpacity(0.6);

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  title: 'Video',
                  onSeeAll: items.isNotEmpty
                      ? () => Navigator.pushNamed(context, AppRoutes.allVideos)
                      : null,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 190, // Adjusted height to fit content
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
                      ? Center(
                          child: Text(
                            'Tidak ada video tersedia',
                            style: TextStyle(color: textSecondaryColor),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final video = items[index];
                            final thumbnailUrl = _thumbUrl(video);

                            return InkWell(
                              onTap: () => _openYoutubeVideo(video),
                              child: SizedBox(
                                width: 270,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        children: [
                                          thumbnailUrl.isNotEmpty
                                              ? Image.network(
                                                  thumbnailUrl,
                                                  width: 270,
                                                  height: 150,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder:
                                                      (
                                                        context,
                                                        child,
                                                        progress,
                                                      ) {
                                                        if (progress == null)
                                                          return child;
                                                        return SizedBox(
                                                          width: 270,
                                                          height: 150,
                                                          child: const Center(
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
                                                      ) => Container(
                                                        width: 270,
                                                        height: 150,
                                                        color:
                                                            colorScheme.surface,
                                                        child: Center(
                                                          child: Icon(
                                                            Icons
                                                                .broken_image,
                                                            size: 40,
                                                            color:
                                                                textSecondaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                )
                                              : Container(
                                                  width: 270,
                                                  height: 150,
                                                  color: colorScheme.surface,
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.videocam_off,
                                                      size: 40,
                                                      color:
                                                          textSecondaryColor,
                                                    ),
                                                  ),
                                                ),
                                          if (thumbnailUrl.isNotEmpty)
                                            Positioned.fill(
                                              child: Center(
                                                child: AnimatedSwitcher(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      color: overlayColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                        8.0,
                                                      ),
                                                      child: Icon(
                                                        Icons.play_arrow,
                                                        color:
                                                            textPrimaryColor,
                                                        size: 40,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      video.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textPrimaryColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
