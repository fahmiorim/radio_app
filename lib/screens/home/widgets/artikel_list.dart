import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';

import '../../../models/artikel_model.dart';

import '../../../widgets/section_title.dart';
import '../../../widgets/skeleton/artikel_skeleton.dart';
import '../../../providers/artikel_provider.dart';
import '../../../screens/artikel/artikel_detail_screen.dart';
import '../../../navigation/bottom_nav.dart';

class ArtikelList extends StatefulWidget {
  const ArtikelList({super.key});

  @override
  State<ArtikelList> createState() => ArtikelListState();
}

class ArtikelListState extends State<ArtikelList>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  bool _isMounted = false;
  List<Artikel>? _lastItems;

  @override
  void initState() {
    super.initState();
    _isMounted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });

    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    await context.read<ArtikelProvider>().init();
    if (forceRefresh) {
      await context.read<ArtikelProvider>().fetchRecentArtikels();
    }
    if (mounted) {
      setState(() {
        _lastItems = List<Artikel>.from(context.read<ArtikelProvider>().recentArtikels);
      });
    }
  }
  
  // Public method to trigger refresh from parent
  Future<void> refreshData() async {
    await _loadData(forceRefresh: true);
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
    super.dispose();
  }

  Future<void> _checkAndRefresh() async {
    if (!mounted) return;

    final provider = context.read<ArtikelProvider>();
    final currentItems = provider.recentArtikels;
    final shouldRefresh = _lastItems == null ||
        !const DeepCollectionEquality().equals(_lastItems, currentItems);

    if (shouldRefresh) {
      await provider.refreshRecent();
      if (mounted) {
        setState(() {
          _lastItems =
              List<Artikel>.from(provider.recentArtikels);
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
  Widget build(BuildContext context) {
    super.build(context);

    final provider = context.watch<ArtikelProvider>();
    final isLoading = provider.isLoadingRecent;
    final error = provider.recentError;
    final artikelList = provider.recentArtikels;

    if (error != null && artikelList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gagal memuat data artikel.\nSilakan coba lagi.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    context.read<ArtikelProvider>().refreshRecent(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: "Artikel",
          onSeeAll: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const BottomNav(initialIndex: 1),
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        if (isLoading && artikelList.isEmpty)
          const ArtikelSkeleton()
        else
          SizedBox(
            height: 220,
            child: RefreshIndicator(
              onRefresh: () => context.read<ArtikelProvider>().refreshRecent(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      key: const PageStorageKey('recent_articles_scroll'),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: artikelList.length > 5
                          ? 5
                          : artikelList.length,
                      padding: const EdgeInsets.only(left: 16),
                      itemBuilder: (context, index) {
                        final artikel = artikelList[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ArtikelDetailScreen(
                                  artikelSlug: artikel.slug,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: SizedBox(
                                    width: 160,
                                    height: 150,
                                    child: artikel.gambarUrl.isEmpty
                                        ? _thumbPlaceholder()
                                        : CachedNetworkImage(
                                            imageUrl: artikel.gambarUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) =>
                                                _thumbLoading(),
                                            errorWidget: (_, __, ___) =>
                                                _thumbPlaceholder(),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  artikel.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  artikel.formattedDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
