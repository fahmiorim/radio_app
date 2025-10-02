import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

import 'package:radio_odan_app/providers/album_provider.dart';
import 'package:radio_odan_app/models/album_model.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';
import 'package:radio_odan_app/widgets/common/mini_player.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';
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
    return Scaffold(
      appBar: CustomAppBar(title: 'Semua Album'),
      body: Stack(
        children: [
          const AppBackground(),
          _buildBody(),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
            child: const MiniPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<AlbumProvider>(
      builder: (context, provider, _) {
        final albums = provider.allAlbums;
        final theme = Theme.of(context);
        final colors = theme.colorScheme;

        if (provider.isLoadingAll && albums.isEmpty) {
          return _buildLoadingSkeleton();
        }

        if (provider.hasErrorAll && albums.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colors.error),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat album',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.errorMessageAll,
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
          );
        }

        if (albums.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_album_outlined,
                  size: 64,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.5),
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
                    color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshAlbums,
          color: colors.primary,
          child: GridView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: albums.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= albums.length) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  ),
                );
              }
              return _AlbumCard(album: albums[index]);
            },
          ),
        );
      },
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
      itemBuilder: (_, _) => Card(
        margin: EdgeInsets.zero,
        color: colors.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colors.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
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
                    color: colors.surfaceContainerHighest,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: colors.surfaceContainerHighest,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Container(
                                height: 12,
                                color: colors.surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: colors.surfaceContainerHighest,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Container(
                                height: 12,
                                color: colors.surfaceContainerHighest,
                              ),
                            ),
                          ],
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
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ), // Reduced vertical margin
      color: colors.surface,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colors.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToAlbumDetail(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 0,
            maxWidth: double.infinity,
            maxHeight: 200, // Limit total height
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAlbumCover(colors),
              _buildAlbumInfo(theme, colors),
            ],
          ),
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
        height: 120, // Reduced height
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          color: colors.surfaceContainerHighest,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ),
        errorWidget: (_, _, _) => Container(
          color: colors.surfaceContainerHighest,
          padding: const EdgeInsets.all(16),
          child: Icon(Icons.error_outline, color: colors.error),
        ),
      ),
    );
  }

  Widget _buildAlbumInfo(ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ), // Reduced padding
      child: Column(
        mainAxisSize: MainAxisSize.min, // Take minimum vertical space
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
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 12, // Even smaller font
        height: 1.1, // Tighter line height
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAlbumMetadata(ThemeData theme, ColorScheme colors) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _buildInfoChip(
          icon: Icons.photo_library_outlined,
          text: '${album.totalPhotos} Foto',
          theme: theme,
          colors: colors,
        ),
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
      MaterialPageRoute(builder: (_) => AlbumDetailScreen(slug: album.slug)),
    );
  }
}
