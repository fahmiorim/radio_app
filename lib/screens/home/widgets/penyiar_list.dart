import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';

import '../../../../models/penyiar_model.dart';
import '../../../../providers/penyiar_provider.dart';
import '../../../../widgets/section_title.dart';
import '../../../../widgets/skeleton/penyiar_skeleton.dart';

class PenyiarList extends StatefulWidget {
  const PenyiarList({super.key});

  @override
  State<PenyiarList> createState() => PenyiarListState();
}

class PenyiarListState extends State<PenyiarList>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  bool _isMounted = false;

  List<Penyiar>? _lastItems;

  @override
  void initState() {
    super.initState();
    _isMounted = true;

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });

    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    await context.read<PenyiarProvider>().init();
    if (forceRefresh) {
      await context.read<PenyiarProvider>().refresh();
    } else {
      await context.read<PenyiarProvider>().load();
    }
    if (mounted) {
      setState(() {
        _lastItems = List<Penyiar>.from(context.read<PenyiarProvider>().items);
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
    // Check if we need to refresh when dependencies change
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

    final provider = context.read<PenyiarProvider>();
    final currentItems = provider.items;
    final shouldRefresh =
        _lastItems == null ||
        !const DeepCollectionEquality().equals(_lastItems, currentItems);

    if (shouldRefresh) {
      await provider.refresh();
      if (mounted) {
        setState(() {
          _lastItems = List<Penyiar>.from(provider.items);
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

    return Selector<PenyiarProvider, Map<String, dynamic>>(
      selector: (_, provider) => ({
        'isLoading': provider.isLoading,
        'items': List<Penyiar>.from(
          provider.items,
        ), // Create a new list to ensure proper updates
        'error': provider.error,
      }),
      builder: (context, data, _) {
        final isLoading = data['isLoading'] as bool;
        final items = data['items'] as List<Penyiar>;
        final error = data['error'] as String?;

        if (error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Gagal memuat data penyiar. Silakan coba lagi.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title: 'Penyiar Radio'),
            SizedBox(
              height: 160,
              child: isLoading
                  ? const PenyiarSkeleton()
                  : items.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada data penyiar',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemBuilder: (context, index) {
                        final p = items[index];
                        return Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 12),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              // Foto penyiar
                              Container(
                                width: 110,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                ),
                                child: p.avatarUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: p.avatarUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                              // Overlay nama
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 6,
                                ),
                                color: Colors.black.withOpacity(0.5),
                                child: Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
