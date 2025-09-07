import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:radio_odan_app/providers/album_provider.dart';
import 'package:radio_odan_app/models/album_model.dart';
import 'package:radio_odan_app/config/app_colors.dart';
import 'package:radio_odan_app/widgets/common/mini_player.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String slug;
  const AlbumDetailScreen({super.key, required this.slug});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  late final ScrollController _scrollController;

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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                context.read<AlbumProvider>().fetchAlbumDetail(widget.slug),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),

          Consumer<AlbumProvider>(
            builder: (context, provider, _) {
              if (provider.isLoadingDetail && provider.albumDetail == null) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
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

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 250.0,
          pinned: true,
          backgroundColor: AppColors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            background: Stack(
              fit: StackFit.expand,
              children: [
                // COVER — gunakan URL yang sudah di-resolve
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
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          size: 40,
                        ),
                      ),
                    ),
                  )
                else
                  Container(color: theme.colorScheme.surface),

                // Overlay gradient supaya judul kebaca
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          theme.colorScheme.onSurface.withOpacity(0.65),
                          theme.colorScheme.onSurface.withOpacity(0.15),
                          AppColors.transparent,
                        ],
                        stops: const [0, .4, 1],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              album.name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3.0,
                    color: theme.brightness == Brightness.dark
                        ? theme.colorScheme.onSurface.withOpacity(0.6)
                        : theme.colorScheme.onSurface.withOpacity(0.45),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Deskripsi & meta
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                album.description?.trim().isNotEmpty == true
                    ? album.description!.trim()
                    : 'Tidak ada deskripsi',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16.0),
              ),
              const SizedBox(height: 20),
              Text(
                'Total Foto: ${photos.length}',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
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
              delegate: SliverChildBuilderDelegate((context, index) {
                final photo = photos[index];
                final photoUrl =
                    photo.url; // <- gunakan URL yang sudah di-resolve

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _PhotoViewer(
                          tag: 'photo-${photo.id}',
                          imageUrl: photoUrl,
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'photo-${photo.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Builder(
                        builder: (context) => CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: Icon(
                              Icons.broken_image,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }, childCount: photos.length),
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

}

/// Viewer foto full-screen dengan PhotoView + Hero + cache reuse
class _PhotoViewer extends StatelessWidget {
  final String tag;
  final String imageUrl;
  const _PhotoViewer({required this.tag, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: Center(
        child: Hero(
          tag: tag,
          child: PhotoView(
            imageProvider: CachedNetworkImageProvider(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            backgroundDecoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
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
