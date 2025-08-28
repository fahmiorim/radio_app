import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radio_odan_app/config/app_api_config.dart';
import 'package:radio_odan_app/config/app_colors.dart';
import 'package:radio_odan_app/models/program_model.dart';
import 'package:radio_odan_app/providers/program_provider.dart';
import 'package:radio_odan_app/widgets/app_bar.dart';
import 'package:radio_odan_app/widgets/mini_player.dart';
import 'package:radio_odan_app/widgets/skeleton/all_programs_skeleton.dart';

class AllProgramsScreen extends StatefulWidget {
  const AllProgramsScreen({super.key});

  @override
  State<AllProgramsScreen> createState() => _AllProgramsScreenState();
}

class _AllProgramsScreenState extends State<AllProgramsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    final provider = context.read<ProgramProvider>();
    
    // Only fetch if we don't have any data and not already loading
    if (provider.allPrograms.isEmpty && !provider.isLoadingAll) {
      try {
        await provider.fetchAllPrograms();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memuat daftar program')),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMorePrograms();
    }
  }

  Future<void> _loadMorePrograms() async {
    final provider = context.read<ProgramProvider>();
    if (_isLoadingMore || !provider.hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await provider.loadMorePrograms();
    } catch (e) {
      debugPrint("Gagal memuat program tambahan: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat program tambahan')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.transparent(
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, AppColors.backgroundDark],
                ),
              ),
              child: Stack(
                children: [
                  // Large bubble top right
                  Positioned(
                    top: -50,
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
                  // Medium bubble bottom left
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // Small bubble center
                  Positioned(
                    top: 100,
                    left: 100,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
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

  Widget _buildBody() {
    return Consumer<ProgramProvider>(
      builder: (context, provider, _) {
        // Show loading skeleton only on initial load
        if (provider.isLoadingAll && provider.allPrograms.isEmpty) {
          return const AllProgramsSkeleton();
        }

        // Show error message if there's an error and no programs are loaded
        if (provider.allProgramsError != null && provider.allPrograms.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat daftar program',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.allProgramsError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInitialData,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        // Show empty state if no programs are available
        if (provider.allPrograms.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.radio, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Belum ada program tersedia',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          );
        }

        // Show program list
        return RefreshIndicator(
          onRefresh: () => provider.fetchAllPrograms(),
          child: _buildProgramList(provider),
        );
      },
    );
  }

  Widget _buildProgramList(ProgramProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      // Add this to prevent unnecessary rebuilds
      addAutomaticKeepAlives: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: provider.allPrograms.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= provider.allPrograms.length) {
          return _buildLoader();
        }
        final program = provider.allPrograms[index];
        return _buildProgramItem(program);
      },
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildProgramItem(Program program) {
    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => programProvider.selectProgram(program, context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    image: program.gambar.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(
                              program.gambar.startsWith('http')
                                  ? program.gambar
                                  : '${AppApiConfig.baseUrl}${program.gambar}',
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: program.gambar.isEmpty
                      ? const Icon(
                          Icons.radio,
                          size: 32,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.namaProgram,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (program.penyiarName != null &&
                          program.penyiarName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          program.penyiarName!,
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                      if (program.jadwal != null &&
                          program.jadwal!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  program.jadwal!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
