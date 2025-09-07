import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

import 'package:radio_odan_app/providers/album_provider.dart';
import 'package:radio_odan_app/models/album_model.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';
import 'package:radio_odan_app/widgets/common/mini_player.dart';
import 'album_detail_screen.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';

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
    WidgetsBinding.instance.addObserver(this);

    // Load awal setelah frame pertama agar aman untuk akses context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialAlbums();
      }
    });
  }

  Future<void> _loadInitialAlbums() async {
    final provider = context.read<AlbumProvider>();
    await provider.fetchAllAlbums();
    _lastAlbums = List<AlbumModel>.from(provider.allAlbums);
  }

  Future<void> _refreshAlbums() async {
    final provider = context.read<AlbumProvider>();
    await provider.refreshAlbums();
    _lastAlbums = List<AlbumModel>.from(provider.allAlbums);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tunda ke frame berikutnya agar aman jika memicu setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndRefresh();
      }
    });
  }

  Future<void> _checkAndRefresh() async {
    if (!mounted) return;

    final provider = context.read<AlbumProvider>();
    final currentAlbums = provider.allAlbums;
    final shouldRefresh =
        _lastAlbums == null ||
        !const DeepCollectionEquality().equals(_lastAlbums, currentAlbums);

    if (shouldRefresh) {
      await provider.refreshAlbums();
      if (mounted) {
        setState(() {
          _lastAlbums = List<AlbumModel>.from(provider.allAlbums);
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isMounted) {
      _checkAndRefresh();
    }
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

  void _onScroll() {
    final albumProvider = context.read<AlbumProvider>();
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: CustomAppBar(
        title: 'Semua Album',
        titleColor: colors.onBackground,
        iconColor: colors.onBackground,
      ),
      body: _buildBody(),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Stack(
      children: [
        const AppBackground(),

        Consumer<AlbumProvider>(
          builder: (context, albumProvider, _) {
            // Initial loading
            if (albumProvider.isLoadingAll && albumProvider.allAlbums.isEmpty) {
              return _buildLoadingSkeleton();
            }

            // Error state
            if (albumProvider.hasErrorAll && albumProvider.allAlbums.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memuat album',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        albumProvider.errorMessageAll,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _refreshAlbums,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Empty state
            if (albumProvider.allAlbums.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_album_outlined,
                      size: 64,
                      color: colors.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada album yang tersedia',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cek kembali nanti untuk album terbaru',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            }

            final itemCount =
                albumProvider.allAlbums.length +
                (albumProvider.hasMore ? 1 : 0);

            return RefreshIndicator(
              onRefresh: _refreshAlbums,
              color: Theme.of(context).colorScheme.primary,
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
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
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

  Widget _buildLoadingSkeleton() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => Card(
        margin: EdgeInsets.zero,
        color: colors.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colors.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    color: colors.surfaceVariant,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: colors.surfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 60,
                        height: 12,
                        color: colors.surfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 12,
                        height: 12,
                        color: colors.surfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 40,
                        height: 12,
                        color: colors.surfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Date formatting is handled in _AlbumCard
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album});

  final AlbumModel album;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: colors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colors.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToAlbumDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlbumCover(colors),
            _buildAlbumInfo(theme, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCover(ColorScheme colors) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: CachedNetworkImage(
        imageUrl: album.coverUrl,
        width: double.infinity,
        height: 150,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: colors.surfaceVariant,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: colors.surfaceVariant,
          padding: const EdgeInsets.all(16),
          child: Icon(Icons.error_outline, color: colors.error),
        ),
      ),
    );
  }

  Widget _buildAlbumInfo(ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAlbumTitle(theme, colors),
          const SizedBox(height: 4),
          _buildAlbumMetadata(theme, colors),
        ],
      ),
    );
  }

  Widget _buildAlbumTitle(ThemeData theme, ColorScheme colors) {
    return Text(
      album.title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAlbumMetadata(ThemeData theme, ColorScheme colors) {
    return Row(
      children: [
        _buildInfoChip(
          icon: Icons.photo_library_outlined,
          text: '${album.totalPhotos} Foto',
          theme: theme,
          colors: colors,
        ),
        const SizedBox(width: 12),
        if (album is PhotoModel)
          _buildInfoChip(
            icon: Icons.calendar_today_outlined,
            text: _formatDate((album as PhotoModel).createdAt),
            theme: theme,
            colors: colors,
          ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required ThemeData theme,
    required ColorScheme colors,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _navigateToAlbumDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(slug: album.slug),
      ),
    );
  }
}
