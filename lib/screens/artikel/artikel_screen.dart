import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:radio_odan_app/config/app_theme.dart';
import 'package:radio_odan_app/models/artikel_model.dart';
import 'package:radio_odan_app/providers/artikel_provider.dart';
import 'package:radio_odan_app/widgets/skeleton/artikel_all_skeleton.dart';
import 'artikel_detail_screen.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';

class ArtikelScreen extends StatefulWidget {
  const ArtikelScreen({super.key});

  @override
  State<ArtikelScreen> createState() => _ArtikelScreenState();
}

class _ArtikelScreenState extends State<ArtikelScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _isMounted = false;
  List<Artikel>? _lastItems;

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

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await context.read<ArtikelProvider>().refresh();
    } else {
      await context.read<ArtikelProvider>().fetchArtikels();
    }
    if (mounted) {
      setState(() {
        _lastItems = List<Artikel>.from(
          context.read<ArtikelProvider>().artikels,
        );
      });
    }
  }

  Future<void> _checkAndRefresh() async {
    if (!mounted) return;

    final provider = context.read<ArtikelProvider>();
    final currentItems = provider.artikels;
    final shouldRefresh =
        _lastItems == null ||
        !const DeepCollectionEquality().equals(_lastItems, currentItems);

    if (shouldRefresh) {
      await provider.refresh();
      if (mounted) {
        setState(() {
          _lastItems = List<Artikel>.from(provider.artikels);
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar.transparent(
        context: context,
        title: 'Artikel',
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: theme.colorScheme.background,
              child: Stack(
                children: [
                  // Top-right bubble
                  AppTheme.bubble(
                    context: context,
                    size: 200,
                    top: 50,
                    right: -50,
                    opacity: isDarkMode ? 0.1 : 0.03,
                    usePrimaryColor: true,
                  ),
                  // Bottom-left bubble
                  AppTheme.bubble(
                    context: context,
                    size: 150,
                    bottom: -30,
                    left: -30,
                    opacity: isDarkMode ? 0.08 : 0.03,
                    usePrimaryColor: true,
                  ),
                ],
              ),
            ),
          ),
          Consumer<ArtikelProvider>(builder: (_, p, __) => _buildBody(p)),
        ],
      ),
    );
  }

  Widget _buildBody(ArtikelProvider p) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    if (p.isLoading && p.artikels.isEmpty) {
      return const ArtikelAllSkeleton();
    }

    if (p.error != null && p.artikels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: colors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Gagal memuat artikel: ${p.error}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => p.refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

    return RefreshIndicator(
      onRefresh: () => p.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: p.artikels.length + (p.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= p.artikels.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final artikel = p.artikels[index];
          return _buildArtikelItem(context, artikel);
        },
      ),
    );
  }

  Widget _buildArtikelItem(BuildContext context, Artikel artikel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArtikelDetailScreen(artikelSlug: artikel.slug),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ArtikelThumb(url: artikel.gambarUrl),
                const SizedBox(height: 12),
                Text(
                  artikel.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (artikel.excerptPlain.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    artikel.excerptPlain,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.8),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (artikel.user.isNotEmpty) ...[
                      Text(
                        artikel.user,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      artikel.formattedDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtikelThumb extends StatelessWidget {
  final String url;
  const _ArtikelThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: double.infinity,
        height: w > 400 ? 200 : 180,
        child: url.isEmpty
            ? _placeholder()
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => _loading(),
                errorWidget: (_, __, ___) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() => Builder(
    builder: (context) => Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image,
        size: 40,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
    ),
  );

  Widget _loading() => const Center(
    child: SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}
