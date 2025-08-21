import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/dummy_video.dart';
import '../../../models/video_model.dart';
import '../../../widgets/skeleton/video_list_skeleton.dart'; // import skeleton

class VideoList extends StatefulWidget {
  const VideoList({super.key});

  @override
  State<VideoList> createState() => _VideoListState();
}

class _VideoListState extends State<VideoList> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _openYoutubeVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Video',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: _isLoading
              ? const VideoListSkeleton() // pakai skeleton dari folder
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: videoGalleries.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final VideoModel video = videoGalleries[index];
                    final videoId =
                        Uri.tryParse(video.videoUrl)?.queryParameters['v'] ??
                        Uri.parse(video.videoUrl).pathSegments.last;
                    final thumbnailUrl =
                        'https://img.youtube.com/vi/$videoId/0.jpg';

                    return InkWell(
                      onTap: () => _openYoutubeVideo(video.videoUrl),
                      child: SizedBox(
                        width: 320,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  child: Image.network(
                                    thumbnailUrl,
                                    width: 320,
                                    height: 180,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Image.asset(
                                      'assets/icons/youtube_logo.png',
                                      width: 80,
                                      height: 80,
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
  }
}
