import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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

class _VideoListState extends State<VideoList> {
  @override
  void initState() {
    super.initState();
    // Fetch videos when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoProvider>().fetchRecentVideos();
    });
  }

  Future<void> _openYoutubeVideo(VideoModel video) async {
    final uri = Uri.parse(video.youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Video',
              onSeeAll: videoProvider.hasRecentVideos
                  ? () {
                      Navigator.pushNamed(context, AppRoutes.allVideos);
                    }
                  : null,
            ),
            SizedBox(
              height: 280,
              child: videoProvider.isLoadingRecent
                  ? const VideoListSkeleton()
                  : videoProvider.hasErrorRecent
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(videoProvider.errorMessageRecent),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: videoProvider.fetchRecentVideos,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        )
                      : videoProvider.recentVideos.isEmpty
                          ? const Center(child: Text('Tidak ada video tersedia'))
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: videoProvider.recentVideos.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final video = videoProvider.recentVideos[index];
                                final thumbnailUrl = video.thumbnailUrl.isNotEmpty
                                    ? video.thumbnailUrl
                                    : 'https://img.youtube.com/vi/${video.youtubeId}/0.jpg';

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
                                              child: Image.network(
                                                thumbnailUrl,
                                                width: 320,
                                                height: 180,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return const Center(
                                                    child: CircularProgressIndicator(),
                                                  );
                                                },
                                                errorBuilder: (context, error, stackTrace) => const Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                            Positioned.fill(
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black54,
                                                    borderRadius: BorderRadius.circular(50),
                                                  ),
                                                  child: const Icon(
                                                    Icons.play_arrow,
                                                    color: Colors.white,
                                                    size: 40,
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
