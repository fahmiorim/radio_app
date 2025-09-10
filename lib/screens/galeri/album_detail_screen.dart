import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:radio_odan_app/providers/album_provider.dart';
import 'package:radio_odan_app/models/album_model.dart';
import 'package:radio_odan_app/widgets/common/mini_player.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String slug;
  const AlbumDetailScreen({super.key, required this.slug});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  late final ScrollController _scrollController;

  // Tinggi MiniPlayer untuk padding konten agar tidak ketutupan
  static const double _miniPlayerHeight = 72;

  Widget _buildPlaceholder() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface.withOpacity(0.8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library,
            size: 40,
            color: cs.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada gambar',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlbumProvider>().fetchAlbumDetail(widget.slug);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildErrorWidget(String message) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: cs.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<AlbumProvider>().fetchAlbumDetail(widget.slug),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Album'),
      body: Stack(
        children: [
          const AppBackground(),
          // Konten
          Consumer<AlbumProvider>(
            builder: (context, provider, _) {
              if (provider.isLoadingDetail && provider.albumDetail == null) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  ),
                );
              }

              if (provider.detailError != null) {
                return _buildErrorWidget(
                  provider.detailError ?? 'Gagal memuat detail album',
                );
              }

              final albumDetail = provider.albumDetail;
              if (albumDetail == null) {
                return _buildErrorWidget('Data album tidak valid');
              }

              return _buildAlbumDetail(context, albumDetail);
            },
          ),
          // MiniPlayer menempel di bawah
          const Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayer()),
        ],
      ),
    );
  }

  Widget _buildAlbumDetail(BuildContext context, AlbumDetailModel albumDetail) {
    final theme = Theme.of(context);
    final album = albumDetail.album;
    final photos = albumDetail.photos;
    final hasPhotos = photos.isNotEmpty;

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 900 ? 4 : (width >= 600 ? 3 : 2);

    // List berguna untuk viewer galeri (urls & hero tags)
    final imageUrls = photos.map((p) => p.url as String? ?? '').toList();
    final heroTags = photos.map((p) => 'photo-${p.id}').toList();

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header Image
        SliverToBoxAdapter(
          child: SizedBox(
            height: 250,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (album.coverUrl.isNotEmpty)
                  Hero(
                    tag: 'album-${album.slug}',
                    child: CachedNetworkImage(
                      imageUrl: album.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: theme.colorScheme.surface),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.surface,
                        child: Icon(
                          Icons.error,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          size: 40,
                        ),
                      ),
                    ),
                  )
                else
                  Container(color: theme.colorScheme.surface),

                // Overlay gradien tipis biar judul kebaca
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [0.0, 0.6, 1.0],
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.black.withOpacity(0.15),
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

        // Title Section
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              album.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),

        // Deskripsi & meta
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                album.description?.trim().isNotEmpty == true
                    ? album.description!.trim()
                    : 'Tidak ada deskripsi',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Total Foto: ${photos.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),

        // Grid foto
        if (hasPhotos)
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final photo = photos[index];
                  final photoUrl = photo.url as String? ?? '';
                  final tag = heroTags[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _PhotoGalleryViewer(
                            imageUrls: imageUrls,
                            heroTags: heroTags,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: tag,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: photoUrl.isEmpty
                            ? _buildPlaceholder()
                            : CachedNetworkImage(
                                imageUrl: photoUrl,
                                fit: BoxFit.cover,
                                // optional: perkecil penggunaan memori
                                memCacheWidth:
                                    ((MediaQuery.of(context).size.width /
                                                crossAxisCount) *
                                            MediaQuery.of(
                                              context,
                                            ).devicePixelRatio)
                                        .round(),
                                placeholder: (context, url) =>
                                    _buildPlaceholder(),
                                errorWidget: (context, url, error) =>
                                    _buildPlaceholder(),
                              ),
                      ),
                    ),
                  );
                },
                // ✅ PENTING: batasi jumlah item
                childCount: photos.length,
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'Belum ada foto di album ini',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),

        // Padding bawah supaya tidak ketutup MiniPlayer
        SliverToBoxAdapter(child: SizedBox(height: _miniPlayerHeight + 16)),
      ],
    );
  }
}

/// Galeri foto full-screen (swipe) dengan PhotoViewGallery + Hero
class _PhotoGalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final List<String> heroTags;
  final int initialIndex;

  const _PhotoGalleryViewer({
    required this.imageUrls,
    required this.heroTags,
    required this.initialIndex,
  });

  @override
  State<_PhotoGalleryViewer> createState() => _PhotoGalleryViewerState();
}

class _PhotoGalleryViewerState extends State<_PhotoGalleryViewer> {
  late final PageController _pageController;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        iconTheme: IconThemeData(color: cs.onSurface),
        title: Text(
          '${_current + 1} / ${widget.imageUrls.length}',
          style: TextStyle(color: cs.onSurface),
        ),
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: widget.imageUrls.length,
        builder: (context, index) {
          final url = widget.imageUrls[index];
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(
              tag: widget.heroTags[index],
            ),
            errorBuilder: (context, error, stackTrace) => Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          );
        },
        backgroundDecoration: BoxDecoration(color: cs.surface),
        onPageChanged: (i) => setState(() => _current = i),
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        ),
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.only(bottom: 0),
        child: MiniPlayer(),
      ),
    );
  }
}
