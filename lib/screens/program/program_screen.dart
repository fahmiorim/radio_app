import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:radio_odan_app/models/program_model.dart';
import 'package:radio_odan_app/providers/program_provider.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';
import 'package:radio_odan_app/widgets/common/mini_player.dart';
import 'package:radio_odan_app/widgets/skeleton/all_programs_skeleton.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';

// ⬇️ Import detail screen
import 'package:radio_odan_app/screens/program/program_detail_screen.dart';

class AllProgramsScreen extends StatefulWidget {
  const AllProgramsScreen({super.key});

  @override
  State<AllProgramsScreen> createState() => _AllProgramsScreenState();
}

class _AllProgramsScreenState extends State<AllProgramsScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scrollController.addListener(_onScroll);

    // Load awal setelah frame pertama agar aman.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<ProgramProvider>();
      // Kalau list kosong → load, kalau sudah ada & stale → refresh.
      if (prov.allPrograms.isEmpty) {
        await prov.loadList(cacheFirst: true);
      } else if (prov.shouldRefreshListOnResume()) {
        await prov.refreshList();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  // Auto-refresh hemat saat balik dari background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final prov = context.read<ProgramProvider>();
      if (prov.shouldRefreshListOnResume()) {
        prov.refreshList();
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Prefetch saat 200px menjelang akhir
    final position = _scrollController.position;
    final trigger = position.maxScrollExtent - 200;

    if (position.pixels >= trigger) _loadMorePrograms();
  }

  Future<void> _loadMorePrograms() async {
    final provider = context.read<ProgramProvider>();
    if (_isLoadingMore || !provider.hasMore) return;

    setState(() => _isLoadingMore = true);
    try {
      await provider.loadMore();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat program tambahan')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Semua Program'),
      body: Stack(
        children: [
          const AppBackground(),
          // Main content
          _buildBody(),
          // Mini Player
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
            child: const MiniPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<ProgramProvider>(
      builder: (context, provider, _) {
        // Loading awal
        if (provider.isLoadingList && provider.allPrograms.isEmpty) {
          return const AllProgramsSkeleton();
        }

        // Error & kosong
        if (provider.listError != null && provider.allPrograms.isEmpty) {
          final theme = Theme.of(context);
          final colors = theme.colorScheme;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat daftar program',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.listError!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.loadList(cacheFirst: false),
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

        // Kosong tanpa error
        if (provider.allPrograms.isEmpty) {
          final theme = Theme.of(context);
          final colors = theme.colorScheme;

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.radio,
                  size: 64,
                  color: colors.onSurfaceVariant.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada program tersedia',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // List
        return RefreshIndicator(
          onRefresh: () => provider.refreshList(),
          child: _buildProgramList(provider),
        );
      },
    );
  }

  Widget _buildProgramList(ProgramProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      addAutomaticKeepAlives: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), // ruang MiniPlayer
      itemCount: provider.allPrograms.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= provider.allPrograms.length) {
          // Loader untuk infinite scroll
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final program = provider.allPrograms[index];
        return _buildProgramItem(program);
      },
    );
  }

  Widget _buildProgramItem(ProgramModel program) {
    final prov = context.read<ProgramProvider>();
    final url = program.gambarUrl;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.surface, colors.surface.withOpacity(0.9)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            prov.selectProgram(program);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProgramDetailScreen(),
                settings: RouteSettings(arguments: program.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with image and title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail with border
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.primary.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(width: 16),

                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with gradient text
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                colors.primary,
                                colors.primary.withOpacity(0.8),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              program.namaProgram,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Schedule row
                          if ((program.jadwal ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.schedule_rounded,
                                    size: 16,
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    program.jadwal!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Builder(
    builder: (context) => Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.6),
            Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.radio_rounded,
        size: 32,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
      ),
    ),
  );

  Widget _thumbLoading() => Center(
    child: SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}
