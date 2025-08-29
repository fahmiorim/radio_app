import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:radio_odan_app/config/app_colors.dart';
import 'package:radio_odan_app/models/event_model.dart';
import 'package:radio_odan_app/providers/event_provider.dart';
import 'package:radio_odan_app/widgets/app_bar.dart';
import 'package:radio_odan_app/widgets/mini_player.dart';
import 'package:radio_odan_app/widgets/skeleton/event_skeleton.dart';

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) return;
    _isInit = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<EventProvider>();
      if (!provider.isLoading && provider.events.isEmpty) {
        provider.refresh();
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
    if (!provider.hasMore || provider.isLoadingMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 48) {
      provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('all_events_screen'),
      appBar: CustomAppBar.transparent(title: 'Semua Event'),
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
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
                  Positioned(top: 50, right: -50, child: _bubble(200, 0.05)),
                  Positioned(bottom: -50, left: -50, child: _bubble(250, 0.03)),
                ],
              ),
            ),
          ),
          _buildBody(),
          const Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayer()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<EventProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.events.isEmpty) {
          return const EventSkeleton();
        }

        if (provider.error != null && provider.events.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat event:\n${provider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
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

        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 100,
            ),
            itemCount: provider.events.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.events.length) {
                return provider.isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              }
              return _eventCard(provider.events[index]);
            },
          ),
        );
      },
    );
  }

  Widget _eventCard(Event e) {
    final url = e.gambarUrl;

    return Card(
      key: Key('event_${e.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surface.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // TODO: buka detail event kalau sudah ada screen-nya
          // context.read<EventProvider>().selectEvent(e, context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: url.isEmpty
                      ? _thumbPlaceholder()
                      : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _thumbLoading(),
                          errorWidget: (_, __, ___) => _thumbPlaceholder(),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                e.judul,
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
                e.formattedTanggal,
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

  Widget _bubble(double size, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(opacity),
    ),
  );
}
