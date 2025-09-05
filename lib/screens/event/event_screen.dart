import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:radio_odan_app/config/app_routes.dart';

import 'package:radio_odan_app/models/event_model.dart';
import 'package:radio_odan_app/config/app_theme.dart';
import 'package:radio_odan_app/providers/event_provider.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';
import 'package:radio_odan_app/widgets/common/mini_player.dart';
import 'package:radio_odan_app/widgets/skeleton/event_skeleton.dart';

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _isMounted = false;
  List<Event>? _lastItems;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });

    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _loadData() async {
    await context.read<EventProvider>().refresh();
    _lastItems = List<Event>.from(context.read<EventProvider>().events);
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRefresh() async {
    if (!mounted) return;

    final provider = context.read<EventProvider>();
    final currentItems = provider.events;
    final shouldRefresh =
        _lastItems == null ||
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      key: const Key('all_events_screen'),
      appBar: CustomAppBar.transparent(
        context: context,
        title: 'Semua Event',
      ),
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: colors.surface,
              child: Stack(
                children: [
                  AppTheme.bubble(
                    context: context,
                    size: 200,
                    top: 50,
                    right: -50,
                    opacity: isDarkMode ? 0.1 : 0.03,
                    usePrimaryColor: true,
                  ),
                  AppTheme.bubble(
                    context: context,
                    size: 250,
                    bottom: -50,
                    left: -50,
                    opacity: isDarkMode ? 0.15 : 0.04,
                    usePrimaryColor: true,
                  ),
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
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat event',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.events.isEmpty) {
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 48,
                  color: colors.onSurfaceVariant.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada event yang tersedia',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cek kembali nanti untuk event terbaru',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
      color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.eventDetail, arguments: e);
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
                      ? _thumbPlaceholder(context)
                      : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _thumbLoading(),
                          errorWidget: (_, __, ___) =>
                              _thumbPlaceholder(context),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                e.judul,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                e.formattedTanggal,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
    alignment: Alignment.center,
    child: Icon(
      Icons.image_not_supported,
      size: 40,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
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
