import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/section_title.dart';
import '../../../widgets/skeleton/event_skeleton.dart';
import '../../../providers/event_provider.dart';
import '../../../screens/event/all_events_screen.dart';

class EventList extends StatefulWidget {
  const EventList({super.key});

  @override
  State<EventList> createState() => _EventListState();
}

class _EventListState extends State<EventList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // biar state tetap hidup (gak rebuild)

  @override
  void initState() {
    super.initState();
    // Load data hanya jika belum dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EventProvider>(context, listen: false);
      if (provider.events.isEmpty) {
        provider.fetchEvents();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // wajib kalau pakai AutomaticKeepAliveClientMixin

    final isLoading = context.watch<EventProvider>().isLoading;
    final eventList = context.watch<EventProvider>().events;
    final error = context.watch<EventProvider>().error;

    // Handle error
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Gagal memuat data event. Silakan coba lagi.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: "Event",
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AllEventsScreen()),
            );
          },
        ),
        const SizedBox(height: 8),
        isLoading
            ? const EventSkeleton()
            : SizedBox(
                height: 300,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  physics: const BouncingScrollPhysics(),
                  itemCount: eventList.length,
                  itemBuilder: (context, index) {
                    final event = eventList[index];
                    return GestureDetector(
                      onTap: () {
                        // Navigation to event detail removed
                      },
                      child: Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Image.network(
                                event.gambarUrl,
                                height: 220,
                                width: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 100),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event.judul,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              event.formattedTanggal,
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
}
