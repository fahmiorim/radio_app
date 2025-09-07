import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import 'package:radio_odan_app/models/album_model.dart';
import 'package:radio_odan_app/providers/album_provider.dart';
import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/widgets/skeleton/album_list_skeleton.dart';
import 'package:radio_odan_app/widgets/common/section_title.dart';
import 'package:radio_odan_app/screens/galeri/album_detail_screen.dart';
import 'package:radio_odan_app/config/app_colors.dart';

class AlbumList extends StatefulWidget {
  const AlbumList({super.key});

  @override
  State<AlbumList> createState() => _AlbumListState();
}

class _AlbumListState extends State<AlbumList> with WidgetsBindingObserver {

  bool _isMounted = false;
  List<AlbumModel>? _lastAlbums;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addObserver(this);

    // Load data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;

    try {
      final provider = Provider.of<AlbumProvider>(context, listen: false);
      await provider.fetchFeaturedAlbums(forceRefresh: forceRefresh);

      if (mounted) {
        setState(() {
          _lastAlbums = List<AlbumModel>.from(provider.featuredAlbums);
        });
      }
    } catch (e) {
      if (mounted) {}
      rethrow;
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Refresh once after the first build to avoid redundant reloads
  bool _isFirstBuild = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstBuild) {
      _isFirstBuild = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadData(forceRefresh: true);
      });
    }
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

    // Only check for refresh if the app is coming back to the foreground
    final provider = context.read<AlbumProvider>();
    await provider.fetchFeaturedAlbums(forceRefresh: true);
    if (mounted) {
      setState(() {
        _lastAlbums = List<AlbumModel>.from(provider.featuredAlbums);
      });
    }
  }

  Widget _buildAlbumItem(BuildContext context, AlbumModel album) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      constraints: const BoxConstraints(maxWidth: 140, maxHeight: 180),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlbumDetailScreen(slug: album.slug),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image container with fixed aspect ratio
            SizedBox(
              height: 130, // Adjusted height
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Album cover image
                    Image.network(
                      album.coverUrl.isNotEmpty ? album.coverUrl : '',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 32),
                      ),
                    ),

                    // Gradient overlay for better text visibility
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.black.withOpacity(0.7),
                              AppColors.transparent,
                              AppColors.transparent,
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
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${album.photosCount ?? 0}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
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
                        child: Container(color: AppColors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Title and photo count in a column
            Container(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    album.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Photo count
                  Text(
                    '${album.photosCount ?? 0} Foto',
                    style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final albumProvider = Provider.of<AlbumProvider>(context);
    final isLoading = albumProvider.isLoadingFeatured;
    final hasError = albumProvider.hasErrorFeatured;
    final errMsg = albumProvider.errorMessageFeatured;
    final items = albumProvider.featuredAlbums;

    // Only update local state if data has actually changed
    if (!const DeepCollectionEquality().equals(_lastAlbums, items)) {
      _lastAlbums = List<AlbumModel>.from(items);
    }

    return Consumer<AlbumProvider>(
      builder: (context, albumProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Galeri',
              onSeeAll: items.isNotEmpty
                  ? () => Navigator.pushNamed(context, AppRoutes.albumList)
                  : null,
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 400, // Slightly increased height
              child: isLoading && items.isEmpty
                  ? const AlbumListSkeleton()
                  : hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(errMsg, textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _loadData(forceRefresh: true),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
                  : items.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada album tersedia',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                    )
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.8,
                            mainAxisExtent: 180,
                          ),
                      itemCount: items.length > 4 ? 4 : items.length,
                      itemBuilder: (context, index) {
                        return _buildAlbumItem(context, items[index]);
                      },
                    ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
