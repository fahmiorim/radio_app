import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/config/app_colors.dart';
import 'package:radio_odan_app/models/event_model.dart';
import 'package:radio_odan_app/providers/event_provider.dart';
import 'package:radio_odan_app/widgets/app_bar.dart';
import 'package:radio_odan_app/widgets/skeleton/event_skeleton.dart';

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EventProvider>();
      if (!_isInitialized) {
        _isInitialized = true;
        if (provider.events.isEmpty) {
          provider.fetchEvents();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<EventProvider>();
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      provider.loadMoreEvents();
    }
  }

  Widget _buildEventItem(Event event, BuildContext context) {
    return Card(
      key: Key('event_${event.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surface.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          final provider = context.read<EventProvider>();
          provider.selectEvent(event, context);
        },
        borderRadius: BorderRadius.circular(12),
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
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          final totalBytes = loadingProgress.expectedTotalBytes;
                          return Center(
                            child: CircularProgressIndicator(
                              value: totalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      totalBytes
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, size: 40),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 180,
                        color: Colors.grey[300],
                        child: const Icon(Icons.event, size: 40),
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                event.judul,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                event.formattedTanggal,
                style: TextStyle(
                  fontSize: 14, 
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<EventProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const EventSkeleton();
        }

        if (provider.error != null) {
          return Center(
            child: Text(
              'Gagal memuat event: ${provider.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        if (provider.events.isEmpty) {
          return const Center(
            child: Text(
              'Tidak ada event yang tersedia',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return Stack(
          children: [
            // Bubble/Wave Background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, AppColors.backgroundDark],
                  ),
                ),
                child: Stack(
                  children: [
                    // Bubble 1 - Top Right
                    Positioned(
                      top: 50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    // Bubble 2 - Bottom Left
                    Positioned(
                      bottom: -50,
                      left: -50,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.03),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: provider.events.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= provider.events.length) {
                  return provider.isLoadingMore
                      ? _buildLoadingIndicator()
                      : const SizedBox.shrink();
                }
                return _buildEventItem(provider.events[index], context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('all_events_screen'),
      appBar: CustomAppBar.transparent(title: 'Semua Event'),
      backgroundColor: AppColors.backgroundDark,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return _buildBody();
        },
      ),
    );
  }
}
