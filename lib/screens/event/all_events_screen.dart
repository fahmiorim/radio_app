import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../config/app_colors.dart';
import '../../widgets/skeleton/event_skeleton.dart';

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  bool isLoading = true;
  List<Event> eventList = [];
  final EventService _eventService = EventService();
  final ScrollController _scrollController = ScrollController();
  bool _hasMore = true;
  int _page = 1;
  final int _perPage = 10;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore) {
      _loadMoreEvents();
    }
  }

  Future<void> _loadEvents() async {
    try {
      final data = await _eventService.fetchAllEvents(page: _page, perPage: _perPage);
      if (mounted) {
        setState(() {
          eventList = data;
          isLoading = false;
          _hasMore = data.length == _perPage;
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat event: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat daftar event')),
        );
      }
    }
  }

  Future<void> _loadMoreEvents() async {
    if (_isLoadingMore) return;

    try {
      setState(() => _isLoadingMore = true);
      _page++;

      final newEvents = await _eventService.fetchAllEvents(page: _page, perPage: _perPage);

      if (mounted) {
        setState(() {
          eventList.addAll(newEvents);
          _hasMore = newEvents.length == _perPage;
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat event tambahan: $e");
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memuat event tambahan')),
          );
        }
      }
    }
  }

  Widget _buildEventItem(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: event.gambar.isNotEmpty
                  ? Image.network(
                      event.gambarUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 180,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(Icons.event),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              event.judul,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              event.formattedTanggal,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const EventSkeleton();
    }

    if (eventList.isEmpty) {
      return const Center(child: Text('Tidak ada event yang tersedia'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: eventList.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= eventList.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildEventItem(eventList[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Event'),
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.backgroundDark,
      body: _buildBody(),
    );
  }
}
