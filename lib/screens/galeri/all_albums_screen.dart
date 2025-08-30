import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';

import '../../config/app_colors.dart';
import '../../providers/album_provider.dart';
import '../../models/album_model.dart';
import '../../widgets/app_bar.dart';
import 'album_detail_screen.dart';

class AllAlbumsScreen extends StatefulWidget {
  const AllAlbumsScreen({super.key});

  @override
  State<AllAlbumsScreen> createState() => _AllAlbumsScreenState();
}

class _AllAlbumsScreenState extends State<AllAlbumsScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  static const double _infiniteScrollThreshold = 300; // px sebelum mentok
  bool _isMounted = false;
  List<AlbumModel>? _lastAlbums;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });

    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _loadData() async {
    final provider = context.read<AlbumProvider>();
    await provider.fetchAllAlbums();
    _lastAlbums = List<AlbumModel>.from(provider.allAlbums);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndRefresh();
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    WidgetsBinding.instance.removeObserver(this);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isMounted) {
      _checkAndRefresh();
    }
  }

  Future<void> _checkAndRefresh() async {
    if (!mounted) return;

    final provider = context.read<AlbumProvider>();
    final currentAlbums = provider.allAlbums;
    final shouldRefresh = _lastAlbums == null ||
        !const DeepCollectionEquality().equals(_lastAlbums, currentAlbums);

    if (shouldRefresh) {
      await refreshAlbums();
    }
  }

  Future<void> refreshAlbums() async {
    final provider = context.read<AlbumProvider>();
    provider.resetPagination();
    await provider.fetchAllAlbums();
    if (mounted) {
      setState(() {
        _lastAlbums = List<AlbumModel>.from(provider.allAlbums);
      });
    }
  }

  void _onScroll() {
    final albumProvider = Provider.of<AlbumProvider>(context, listen: false);
    if (!albumProvider.isLoadingAll && albumProvider.hasMore) {
      final position = _scrollController.position;
      if (position.pixels + _infiniteScrollThreshold >=
          position.maxScrollExtent) {
        albumProvider.loadMoreAlbums();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: CustomAppBar.transparent(title: 'Semua Album'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        // Background
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
          builder: (context, albumProvider, _) {
            // Initial loading
            if (albumProvider.isLoadingAll && albumProvider.allAlbums.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            }

            // Error state
            if (albumProvider.hasErrorAll) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      albumProvider.errorMessageAll,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: refreshAlbums,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            // Empty state
            if (albumProvider.allAlbums.isEmpty) {
              return const Center(
                child: Text(
                  'Tidak ada album yang tersedia',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final itemCount =
                albumProvider.allAlbums.length +
                (albumProvider.hasMore ? 1 : 0);

            return RefreshIndicator(
              onRefresh: refreshAlbums,
              color: AppColors.primary,
              child: GridView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72, // kartu sedikit tinggi
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  // Footer loader
                  if (index >= albumProvider.allAlbums.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  }

                  final album = albumProvider.allAlbums[index];
                  return _AlbumCard(album: album);
                },
              ),
            );
          },
        ),
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

class _AlbumCard extends StatelessWidget {
  final AlbumModel album;
  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    final coverUrl = album.coverUrl; // gunakan URL yang sudah di-resolve

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlbumDetailScreen(slug: album.slug),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'album-${album.slug}',
                      child: CachedNetworkImage(
                        imageUrl: coverUrl.isNotEmpty ? coverUrl : '',
                        fit: BoxFit.cover,
                        placeholder: (context, _) =>
                            Container(color: AppColors.surfaceLight),
                        errorWidget: (context, _, __) => Container(
                          color: AppColors.surfaceLight,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.photo_album,
                            color: Colors.white54,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.75),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Title & meta
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.photo_library,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${album.photosCount ?? 0} Foto',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // (opsional) bisa tambah footer info lain di sini
          ],
        ),
      ),
    );
  }
}
