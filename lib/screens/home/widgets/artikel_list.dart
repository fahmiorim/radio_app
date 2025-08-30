import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';

import '../../../models/artikel_model.dart';
import '../../../providers/artikel_provider.dart';
import '../../../widgets/skeleton/artikel_skeleton.dart';
import '../../../screens/artikel/artikel_detail_screen.dart';
import '../../../config/app_colors.dart';

class ArtikelList extends StatefulWidget {
  const ArtikelList({super.key});

  @override
  State<ArtikelList> createState() => ArtikelListState();
}

class ArtikelListState extends State<ArtikelList>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _isMounted = false;
  List<Artikel>? _lastItems;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addObserver(this);

    // Load data after first frame to avoid context issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await context.read<ArtikelProvider>().refreshRecent();
    } else {
      await context.read<ArtikelProvider>().fetchRecentArtikels();
    }
    if (mounted) {
      setState(() {
        _lastItems = List<Artikel>.from(
          context.read<ArtikelProvider>().recentArtikels,
        );
      });
    }
  }

  // Public method: bisa dipanggil parent untuk hard refresh
  Future<void> refreshData() async {
    await _loadData(forceRefresh: true);
  }

  Future<void> _checkAndRefresh() async {
    if (!mounted) return;

    final provider = context.read<ArtikelProvider>();
    final currentItems = provider.recentArtikels;
    final shouldRefresh =
        _lastItems == null ||
        !const DeepCollectionEquality().equals(_lastItems, currentItems);

    if (shouldRefresh) {
      await provider.refreshRecent();
      if (mounted) {
        setState(() {
          _lastItems = List<Artikel>.from(provider.recentArtikels);
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
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onScroll() {
    final p = context.read<ArtikelProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 48 &&
        !p.isLoadingMore &&
        p.hasMore) {
      p.loadMoreArtikels();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ArtikelProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingRecent && provider.recentArtikels.isEmpty) {
          return const ArtikelSkeleton();
        }

        if (provider.recentError != null && provider.recentArtikels.isEmpty) {
          return _buildErrorWidget(provider);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: ListView.builder(
                key: const PageStorageKey('recent_articles_scroll'),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: provider.recentArtikels.length > 5
                    ? 5
                    : provider.recentArtikels.length,
                padding: const EdgeInsets.only(left: 16),
                itemBuilder: (context, index) {
                  final artikel = provider.recentArtikels[index];
                  return _buildArtikelItem(context, artikel);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorWidget(ArtikelProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat artikel: ${provider.recentError}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.refreshRecent(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtikelItem(BuildContext context, Artikel artikel) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return ArtikelDetailScreen(artikelSlug: artikel.slug);
          },
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 160,
                height: 150,
                color: AppColors.cardBackground,
                child: artikel.gambarUrl.isEmpty
                    ? _thumbPlaceholder()
                    : CachedNetworkImage(
                        imageUrl: artikel.gambarUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _thumbLoading(),
                        errorWidget: (_, __, ___) => _thumbPlaceholder(),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artikel.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              artikel.formattedDate,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
    color: Colors.grey[900],
    alignment: Alignment.center,
    child: const Icon(
      Icons.image_not_supported,
      size: 40,
      color: Colors.white38,
    ),
  );

  Widget _thumbLoading() => const Center(
    child: SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}
