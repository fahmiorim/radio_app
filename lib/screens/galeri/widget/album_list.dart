import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

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

class _AlbumListState extends State<AlbumList>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  bool _isMounted = false;
  List<AlbumModel>? _lastAlbums;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addObserver(this);

    // Fetch albums ketika widget siap (hindari panggil di build)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<AlbumProvider>();
      await provider.fetchFeaturedAlbums();
      setState(() {
        _lastAlbums = List<AlbumModel>.from(provider.featuredAlbums);
      });
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tunda ke frame berikutnya agar aman jika memicu setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAndRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isMounted) {
      // Tunda ke frame berikutnya agar aman terhadap build yang sedang berjalan
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkAndRefresh();
      });
    }
  }

  Future<void> _checkAndRefresh() async {
    if (!mounted) return;

    final provider = context.read<AlbumProvider>();
    final current = provider.featuredAlbums;
    final shouldRefresh = _lastAlbums == null ||
        !const DeepCollectionEquality().equals(_lastAlbums, current);

    if (shouldRefresh) {
      await provider.fetchFeaturedAlbums();
      if (mounted) {
        setState(() {
          _lastAlbums = List<AlbumModel>.from(provider.featuredAlbums);
        });
      }
    }
  }

  Widget _buildAlbumItem(BuildContext context, AlbumModel album) {
    return SizedBox(
      width: 160,
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
            // Pastikan rasio konsisten agar list nggak "lompat-lompat"
            AspectRatio(
              aspectRatio: 1, // kotak (1:1). Ubah sesuai desain (mis. 4/5)
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Pakai URL yang sudah di-resolve
                    Image.network(
                      album.coverUrl.isNotEmpty ? album.coverUrl : '',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(color: Colors.grey[300]);
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 32),
                      ),
                    ),

                    // Overlay gradient biar teks kebaca
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.65),
                              Colors.black.withOpacity(0.15),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Badge jumlah foto (opsional)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.photo_library_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${album.photosCount ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Hero untuk transisi halus ke halaman detail (optional)
                    Positioned.fill(
                      child: Hero(
                        tag: 'album-${album.slug}',
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Judul
            Text(
              album.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Subteks jumlah foto
            const SizedBox(height: 2),
            Text(
              '${album.photosCount ?? 0} Foto',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                Text(
                  albumProvider.errorMessageFeatured,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
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
              height: 220, // total tinggi kartu (rasio 1:1 + teks)
              child: ListView.separated(
                padding: const EdgeInsets.only(right: 4),
                scrollDirection: Axis.horizontal,
                itemCount: albumProvider.featuredAlbums.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) => _buildAlbumItem(
                  context,
                  albumProvider.featuredAlbums[index],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
