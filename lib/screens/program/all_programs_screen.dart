import 'package:flutter/material.dart';

import '../../config/app_routes.dart';
import '../../config/app_colors.dart';
import '../../models/program_model.dart';
import '../../services/program_service.dart';
import '../../widgets/skeleton/program_skeleton.dart';
import '../../widgets/mini_player.dart';

class AllProgramsScreen extends StatefulWidget {
  const AllProgramsScreen({super.key});

  @override
  State<AllProgramsScreen> createState() => _AllProgramsScreenState();
}

class _AllProgramsScreenState extends State<AllProgramsScreen> {
  bool isLoading = true;
  List<Program> programList = [];
  final programService = ProgramService();
  final ScrollController _scrollController = ScrollController();
  bool _hasMore = true;
  int _page = 1;
  final int _perPage = 10;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
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
        !_isLoadingMore &&
        _hasMore) {
      _loadMorePrograms();
    }
  }

  Future<void> _loadPrograms() async {
    try {
      final data = await programService.fetchPrograms(
        page: _page,
        perPage: _perPage,
      );

      if (mounted) {
        setState(() {
          programList = data;
          isLoading = false;
          _hasMore = data.length == _perPage;
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat program: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat daftar program')),
        );
      }
    }
  }

  Future<void> _loadMorePrograms() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _page + 1;
      final data = await programService.fetchPrograms(
        page: nextPage,
        perPage: _perPage,
      );

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          if (data.isNotEmpty) {
            programList.addAll(data);
            _page = nextPage;
            _hasMore = data.length == _perPage;
          } else {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat program tambahan: $e");
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memuat program tambahan')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'Semua Program',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          _buildBody(),
          // Mini Player
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const MiniPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80), // Padding untuk MiniPlayer
      child: isLoading
          ? const Center(child: ProgramSkeleton())
          : programList.isEmpty
              ? const Center(child: Text('Tidak ada program tersedia'))
              : _buildProgramList(),
    );
  }

  Widget _buildProgramList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: programList.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= programList.length) {
          return _buildLoader();
        }
        final program = programList[index];
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.programDetail,
            arguments: program.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  program.gambarUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: AppColors.surfaceLight,
                    child: Icon(Icons.radio, size: 40, color: AppColors.textSecondary),
                  ),
                ),
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
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (program.penyiarName != null && program.penyiarName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          program.penyiarName!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    if (program.jadwal != null && program.jadwal!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          program.jadwal!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
