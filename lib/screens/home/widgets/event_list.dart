import 'package:flutter/material.dart';
import '../../../widgets/section_title.dart';
import '../../../widgets/skeleton/event_skeleton.dart';
import '../../../config/app_routes.dart';
import '../../../models/event_model.dart';
import '../../../services/event_service.dart';

class EventList extends StatefulWidget {
  const EventList({super.key});

  @override
  State<EventList> createState() => _EventListState();
}

class _EventListState extends State<EventList>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = true;
  List<Event> eventList = [];

  @override
  bool get wantKeepAlive => true; // biar state tetap hidup (gak rebuild)

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final data = await EventService().fetchEvents();
      if (mounted) {
        setState(() {
          eventList = data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal ambil data event: $e");
      if (mounted) {
        setState(() {
          isLoading = false; // biar skeleton hilang walau error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // wajib kalau pakai AutomaticKeepAliveClientMixin
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: "Event"),
        const SizedBox(height: 8),
        isLoading
            ? const EventSkeleton()
            : SizedBox(
                height: 300,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(), // smooth scroll
                  shrinkWrap: true,
                  itemCount: eventList.length,
                  padding: const EdgeInsets.only(left: 16),
                  itemBuilder: (context, index) {
                    final event = eventList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.eventDetail,
                          arguments: event,
                        );
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
                              ),
                            ),
                            Text(
                              event.formattedTanggal,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
