import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';

import '../../../models/event_model.dart';

import '../../../widgets/section_title.dart';
import '../../../widgets/skeleton/event_skeleton.dart';
import '../../../providers/event_provider.dart';
import '../../../screens/event/all_events_screen.dart';

class EventList extends StatefulWidget {
  const EventList({super.key});

  @override
  State<EventList> createState() => EventListState();
}

class EventListState extends State<EventList>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  bool _isMounted = false;
  List<Event>? _lastItems;

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
    await context.read<EventProvider>().init();
    if (forceRefresh) {
      await context.read<EventProvider>().refresh();
    } else {
      await context.read<EventProvider>().load(cacheFirst: true);
    }
    if (mounted) {
      setState(() {
        _lastItems = List<Event>.from(context.read<EventProvider>().events);
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

    final provider = context.read<EventProvider>();
    final currentItems = provider.events;
    final shouldRefresh = _lastItems == null ||
        !const DeepCollectionEquality().equals(_lastItems, currentItems);

    if (shouldRefresh) {
      await provider.refresh();
      if (mounted) {
        setState(() {
          _lastItems = List<Event>.from(provider.events);
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

    final prov = context.watch<EventProvider>();
    final isLoading = prov.isLoading;
    final events = prov.events;
    final error = prov.error;

    if (error != null && events.isEmpty) {
      return _errorView(onRetry: () => prov.refresh());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Event',
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllEventsScreen()),
            );
          },
        ),
        const SizedBox(height: 8),
        if (isLoading && events.isEmpty)
          const EventSkeleton()
        else if (events.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              'Belum ada event',
              style: TextStyle(color: Colors.white70),
            ),
          )
        else
          SizedBox(
            height: 300,
            child: ListView.builder(
              key: const PageStorageKey('events_list'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              physics: const BouncingScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final e = events[index];
                final url = e.gambarUrl;

                return GestureDetector(
                  onTap: () {
                    // TODO: buka detail event kalau ada
                  },
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: SizedBox(
                            width: 200,
                            height: 220,
                            child: url.isEmpty
                                ? _thumbPlaceholder()
                                : CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => _thumbLoading(),
                                    errorWidget: (_, __, ___) =>
                                        _thumbPlaceholder(),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.judul,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          e.formattedTanggal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
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
    );
  }

  Widget _thumbPlaceholder() => Container(
    color: Colors.grey[900],
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image, size: 44, color: Colors.white38),
  );

  Widget _thumbLoading() => const Center(
    child: SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  Widget _errorView({required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat data event. Silakan coba lagi.',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
