import 'package:flutter/material.dart';
import '../../../data/dummy_album.dart';
import '../../../config/app_routes.dart';
import '../../../widgets/skeleton/album_list_skeleton.dart';

class AlbumList extends StatefulWidget {
  const AlbumList({super.key});

  @override
  State<AlbumList> createState() => _AlbumListState();
}

class _AlbumListState extends State<AlbumList> {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Album Foto',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const AlbumListSkeleton()
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: imageGalleries.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final album = imageGalleries[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.albumDetail,
                        arguments: album,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              album.coverUrl,
                              fit: BoxFit.cover,
                              cacheWidth: 400,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 100,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 8,
                            child: Text(
                              '${album.title} (${album.photos.length} foto)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
