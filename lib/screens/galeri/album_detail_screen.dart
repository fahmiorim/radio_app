import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/album_provider.dart';
import '../../models/album_model.dart';
import '../../config/app_colors.dart';

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
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                context.read<AlbumProvider>().fetchAlbumDetail(widget.slug),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
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
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Background dekoratif
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, AppColors.backgroundDark],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(top: -50, right: -50, child: _bubble(200)),
                  Positioned(bottom: -30, left: -30, child: _bubble(150)),
                ],
              ),
            ),
          ),

          Consumer<AlbumProvider>(
            builder: (context, provider, _) {
              if (provider.isLoadingDetail && provider.albumDetail == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
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
        ],
      ),
    );
  }

  Widget _buildAlbumDetail(BuildContext context, AlbumDetailModel albumDetail) {
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
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
                          Container(color: AppColors.surface),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.surface,
                        child: const Icon(
                          Icons.error,
                          color: Colors.white54,
                          size: 40,
                        ),
                      ),
                    ),
                  )
                else
                  Container(color: AppColors.surface),

                // Overlay gradient supaya judul kebaca
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
                        stops: const [0, .4, 1],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              album.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3.0,
                    color: Colors.black45,
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
                style: const TextStyle(color: Colors.white, fontSize: 16.0),
              ),
              const SizedBox(height: 20),
              Text(
                'Total Foto: ${photos.length}',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
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
                      child: CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: AppColors.surface),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surface,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                            size: 40,
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
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'Belum ada foto di album ini',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
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

  Widget _bubble(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(0.05),
    ),
  );
}

/// Viewer foto full-screen dengan PhotoView + Hero + cache reuse
class _PhotoViewer extends StatelessWidget {
  final String tag;
  final String imageUrl;
  const _PhotoViewer({required this.tag, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: tag,
          child: PhotoView(
            imageProvider: CachedNetworkImageProvider(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
