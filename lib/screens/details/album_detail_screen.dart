import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../../models/album_model.dart';

class AlbumDetailScreen extends StatelessWidget {
  final AlbumModel album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(album.title), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: album.photos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final photoUrl = album.photos[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenPhoto(
                    photoList: album.photos,
                    initialIndex: index,
                  ),
                ),
              ),
              child: Hero(
                tag: photoUrl,
                child: ClipRRect(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class FullScreenPhoto extends StatefulWidget {
  final List<String> photoList;
  final int initialIndex;

  const FullScreenPhoto({
    super.key,
    required this.photoList,
    required this.initialIndex,
  });

  @override
  State<FullScreenPhoto> createState() => _FullScreenPhotoState();
}

class _FullScreenPhotoState extends State<FullScreenPhoto> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photoList.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final photoPath = widget.photoList[index];
              return Center(
                child: Hero(
                  tag: photoPath,
                  child: PhotoView(
                    imageProvider: AssetImage(photoPath),
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                    basePosition: Alignment.center,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, color: Colors.white),
                  ),
                ),
              );
            },
          ),

          // Tombol close tetap di pojok kanan atas
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Indikator posisi foto
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${currentIndex + 1} / ${widget.photoList.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
