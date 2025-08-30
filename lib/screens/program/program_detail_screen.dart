import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:html/parser.dart' show parse;

import '../../providers/program_provider.dart';
import '../../config/app_colors.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/mini_player.dart';

class ProgramDetailScreen extends StatefulWidget {
  const ProgramDetailScreen({super.key});

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadProgramData();
    }
  }

  Future<void> _loadProgramData() async {
    final programProvider = Provider.of<ProgramProvider>(
      context,
      listen: false,
    );

    // kalau sudah ada selectedProgram (dipilih dari list), gak usah fetch
    if (programProvider.selectedProgram != null) return;

    // kalau datang via route arguments (id)
    final programId = ModalRoute.of(context)?.settings.arguments as int?;
    if (programId == null) return;

    try {
      await programProvider.fetchProgramById(programId);
    } catch (e) {
      rethrow;
    }
  }

  String _parseHtmlString(String htmlString) {
    try {
      final document = parse(htmlString);
      return document.body?.text.trim() ?? htmlString;
    } catch (_) {
      return htmlString;
    }
  }

  Widget _buildInfoCard(String title, String value, {IconData? icon}) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Row(
                children: [
                  Icon(icon, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailImage(String url) {
    // aspect ratio 2:3 sesuai kode kamu
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url.isEmpty
            ? Container(
                color: const Color(0xFF1E1E1E),
                child: const Center(
                  child: Icon(
                    Icons.radio,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFF1E1E1E),
                  child: const Center(
                    child: Icon(
                      Icons.radio,
                      size: 80,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgramProvider>(
      builder: (context, programProvider, _) {
        final program = programProvider.selectedProgram;
        final isLoading = programProvider.isLoadingDetail && program == null;
        final error = programProvider.detailError;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: CustomAppBar.transparent(
            title: program?.namaProgram ?? 'Detail Program',
            titleColor: AppColors.textPrimary,
            iconColor: AppColors.textPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  programProvider.clearSelectedProgram();
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          body: Stack(
            children: [
              // Background gradient + bubbles
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
                      Positioned(top: -50, right: -50, child: _bubble(200)),
                      Positioned(bottom: -30, left: -30, child: _bubble(150)),
                      Positioned(top: 100, left: 100, child: _bubble(50)),
                    ],
                  ),
                ),
              ),

              // Content
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Gagal memuat detail program',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProgramData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (program == null)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.radio,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Program tidak ditemukan',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                )
              else
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 0.0),
                        child: _detailImage(
                          program.gambarUrl,
                        ), // ⬅️ pakai getter
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Text(
                                program.namaProgram,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (program.penyiarName != null &&
                                program.penyiarName!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      program.penyiarName!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 24),

                            if (program.deskripsi.isNotEmpty)
                              _buildInfoCard(
                                'Tentang Program',
                                // deskripsi di model sudah di-strip HTML, ini jaga-jaga
                                _parseHtmlString(program.deskripsi),
                                icon: Icons.info_outline,
                              ),

                            if (program.jadwal != null &&
                                program.jadwal!.isNotEmpty)
                              _buildInfoCard(
                                'Jadwal Siaran',
                                program.jadwal!,
                                icon: Icons.schedule,
                              ),

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MiniPlayer(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bubble(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(0.05),
    ),
  );
}
