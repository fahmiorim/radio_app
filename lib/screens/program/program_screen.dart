import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:radio_odan_app/models/program_model.dart';
import 'package:radio_odan_app/providers/program_provider.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';
import 'package:radio_odan_app/widgets/common/mini_player.dart';
import 'package:radio_odan_app/widgets/skeleton/all_programs_skeleton.dart';
import 'package:radio_odan_app/config/app_theme.dart';
import 'package:radio_odan_app/config/app_colors.dart';

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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: CustomAppBar.transparent(
        context: context,
        title: 'Semua Program',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Bubble/Wave Background
          Positioned.fill(
            child: Container(
              color: theme.colorScheme.background,
              child: Stack(
                children: [
                  AppTheme.bubble(
                    context: context,
                    size: 200,
                    top: -50,
                    right: -50,
                    opacity: isDarkMode ? 0.1 : 0.03,
                    usePrimaryColor: true,
                  ),
                  AppTheme.bubble(
                    context: context,
                    size: 150,
                    bottom: -30,
                    left: -30,
                    opacity: isDarkMode ? 0.08 : 0.03,
                    usePrimaryColor: true,
                  ),
                  AppTheme.bubble(
                    context: context,
                    size: 50,
                    top: 100,
                    left: 100,
                    opacity: isDarkMode ? 0.06 : 0.02,
                    usePrimaryColor: true,
                  ),
                ],
              ),
            ),
          ),
          // Main content
          _buildBody(),
          // Mini Player
          const Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayer()),
        ],
      ),
    );
  }

  // _bubble method removed - using AppTheme.bubble instead

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
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: colors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat daftar program',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onBackground,
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () {
            // 1) set selected di provider (hemat fetch kalau detail butuh data)
            prov.selectProgram(program);

            // 2) navigasi ke ProgramDetailScreen dengan program ID
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProgramDetailScreen(),
                settings: RouteSettings(arguments: program.id),
              ),
            );

            // Catatan:
            // Jika kamu ingin TIDAK set selected (dan selalu fetch by id),
            // gunakan:
            // Navigator.pushNamed(context, '/program/detail', arguments: program.id);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
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
                const SizedBox(width: 16),
                Expanded(child: _ProgramTexts(program: program)),
                Icon(Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Builder(
    builder: (context) => Container(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      alignment: Alignment.center,
      child: Icon(Icons.radio, size: 32, color: Theme.of(context).primaryColor),
    ),
  );

  Widget _thumbLoading() => const Center(
    child: SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

class _ProgramTexts extends StatelessWidget {
  const _ProgramTexts({required this.program});

  final ProgramModel program;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          program.namaProgram,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if ((program.jadwal ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule,
                  size: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  program.jadwal!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
