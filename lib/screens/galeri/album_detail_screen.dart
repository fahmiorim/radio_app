import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/album_service.dart';
import '../../models/album_detail_model.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String slug;

  const AlbumDetailScreen({super.key, required this.slug});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  late Future<AlbumDetailModel> _albumFuture;
  final AlbumService _albumService = AlbumService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAlbum();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAlbum() async {
    setState(() {
      _albumFuture = _albumService.fetchAlbumDetail(widget.slug);
    });
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadAlbum, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<AlbumDetailModel>(
        future: _albumFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorWidget('Gagal memuat detail album');
          }

          if (!snapshot.hasData) {
            return _buildErrorWidget('Data album tidak valid');
          }

          final albumDetail = snapshot.data!;
          return _buildAlbumDetail(albumDetail);
        },
      ),
    );
  }

  Widget _buildAlbumDetail(AlbumDetailModel albumDetail) {
    final album = albumDetail.album;
    final photos = albumDetail.photos;
    final albumName = albumDetail.name.isNotEmpty ? albumDetail.name : album.name;
    final hasPhotos = photos.isNotEmpty;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          expandedHeight: 200.0,
          pinned: true,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          iconTheme: Theme.of(context).appBarTheme.iconTheme,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              albumName,
              style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                fontSize: 16.0,
                color: Colors.white, // Keep white for better visibility on images
              ),
            ),
            background: CachedNetworkImage(
              imageUrl: album.coverImage.isNotEmpty ? album.coverImage : (photos.isNotEmpty ? photos.first.image : ''),
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, size: 40),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                album.description ?? 'Tidak ada deskripsi',
                style: const TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 20),
              Text(
                'Total Foto: ${photos.length}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
        if (hasPhotos)
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final photo = photos[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              backgroundColor: Colors.black,
                              iconTheme: const IconThemeData(color: Colors.white),
                            ),
                            backgroundColor: Colors.black,
                            body: Center(
                              child: PhotoView(
                                imageProvider: NetworkImage(photo.image),
                                minScale: PhotoViewComputedScale.contained,
                                maxScale: PhotoViewComputedScale.covered * 2,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CachedNetworkImage(
                        imageUrl: photo.image,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 40),
                        ),
                      ),
                    ),
                  );
                },
                childCount: photos.length,
              ),
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
}
