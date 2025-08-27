import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_routes.dart';
import '../../../models/video_model.dart';
import '../../../services/video_service.dart';
import '../../../widgets/skeleton/video_list_skeleton.dart';

class VideoList extends StatefulWidget {
  const VideoList({super.key});

  @override
  State<VideoList> createState() => _VideoListState();
}

class _VideoListState extends State<VideoList> {
  bool _isLoading = true;
  bool _hasError = false;
  final List<VideoModel> _videos = [];
  final VideoService _videoService = VideoService();

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    try {
      setState(() => _isLoading = true);
      final response = await _videoService.fetchVideos();
      if (mounted) {
        setState(() {
          _videos.addAll(response['videos'] as List<VideoModel>);
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _openYoutubeVideo(VideoModel video) async {
    final uri = Uri.parse(video.youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Video',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (_videos.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.allVideos);
                },
                child: const Text('Lihat Semua'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: _isLoading
              ? const VideoListSkeleton()
              : _hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Gagal memuat video'),
                          TextButton(
                            onPressed: _fetchVideos,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
                  : _videos.isEmpty
                      ? const Center(child: Text('Tidak ada video tersedia'))
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _videos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final video = _videos[index];
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
                                    errorBuilder: (context, error, stackTrace) => 
                                        const Icon(Icons.broken_image, size: 40),
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
