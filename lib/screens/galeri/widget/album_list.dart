import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/album_model.dart';
import '../../../providers/album_provider.dart';
import '../../../config/app_routes.dart';
import '../../../widgets/skeleton/album_list_skeleton.dart';
import '../../../widgets/section_title.dart';

class AlbumList extends StatefulWidget {
  const AlbumList({super.key});

  @override
  State<AlbumList> createState() => _AlbumListState();
}

class _AlbumListState extends State<AlbumList> {
  @override
  void initState() {
    super.initState();
    // Fetch albums when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final albumProvider = context.read<AlbumProvider>();
      if (!albumProvider.hasFeaturedAlbums) {
        albumProvider.fetchFeaturedAlbums();
      }
    });
  }

  Widget _buildAlbumItem(AlbumModel album) {
    return SizedBox(
      width: 160, // Fixed width for each album item
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.albumDetail,
            arguments: album.slug,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      album.coverImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 36),
                      ),
                    ),
                    // Gradient overlay at the bottom of the image
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 60, // Fixed height for the gradient overlay
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${album.photosCount ?? 0} Foto',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlbumProvider>(
      builder: (context, albumProvider, _) {
        if (albumProvider.isLoadingFeatured) {
          return const AlbumListSkeleton();
        }

        if (albumProvider.hasErrorFeatured) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(albumProvider.errorMessageFeatured),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: albumProvider.fetchFeaturedAlbums,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (albumProvider.featuredAlbums.isEmpty) {
          return const Center(child: Text('Tidak ada album tersedia'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Album',
              onSeeAll: () {
                Navigator.pushNamed(context, AppRoutes.albumList);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: albumProvider.featuredAlbums.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final album = albumProvider.featuredAlbums[index];
                  return _buildAlbumItem(album);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
