import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:radio_odan_app/widgets/common/section_title.dart';
import 'package:radio_odan_app/widgets/skeleton/event_skeleton.dart';
import 'package:radio_odan_app/providers/event_provider.dart';
import 'package:radio_odan_app/screens/event/event_screen.dart';
import 'package:radio_odan_app/screens/event/event_detail_screen.dart';

class EventList extends StatefulWidget {
  const EventList({super.key});

  @override
  State<EventList> createState() => _EventListState();
}

class _EventListState extends State<EventList>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load awal setelah frame pertama (aman dari context issues).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<EventProvider>();

      await prov.init();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Auto-refresh saat kembali dari background (hemat dengan cooldown)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final prov = context.read<EventProvider>();
      if (prov.shouldRefreshOnResume()) {
        prov.refresh();
      }
    }
  }

  void _openAllEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AllEventsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<EventProvider>();
    final isLoading = prov.isLoading;
    final events = prov.events;
    final error = prov.error;

    if (error != null && events.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: 'Event', onSeeAll: null),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat data event',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: prov.refresh,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (!isLoading && events.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: 'Event', onSeeAll: null),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Belum ada event',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Event',
          onSeeAll: events.isNotEmpty ? _openAllEvents : null,
        ),
        const SizedBox(height: 8),
        if (isLoading && events.isEmpty)
          const EventSkeleton()
        else
          SizedBox(
            height: 260,
            child: ListView.builder(
              key: const PageStorageKey('events_list'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 12),
              physics: const BouncingScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final e = events[index];
                final url = e.gambarUrl;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailScreen(event: e),
                      ),
                    );
                  },
                  child: Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 180,
                            height: 180,
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
                        const SizedBox(height: 6),
                        Flexible(
                          child: Text(
                            e.judul,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (e.formattedTanggal.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              e.formattedTanggal,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
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
}
