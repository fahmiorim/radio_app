import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkProgramData();
  }

  void _checkProgramData() {
    final programProvider = Provider.of<ProgramProvider>(
      context,
      listen: false,
    );
    if (programProvider.selectedProgram == null) {
      setState(() {
        _errorMessage = 'Program tidak ditemukan';
        _isLoading = false;
      });
    }
  }

  String _parseHtmlString(String htmlString) {
    try {
      final document = parse(htmlString);
      return document.body?.text.trim() ?? htmlString;
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgramProvider>(
      builder: (context, programProvider, _) {
        final program = programProvider.selectedProgram;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: CustomAppBar.transparent(
            title: program?.namaProgram ?? 'Detail Program',
            titleColor: AppColors.textPrimary,
            iconColor: AppColors.textPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                programProvider.clearSelectedProgram();
                Navigator.of(context).pop();
              },
            ),
          ),
          body: Stack(
            children: [
              // Bubble/Wave Background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
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
              // Content
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    )
                  : program == null
                  ? const Center(
                      child: Text(
                        'Program tidak ditemukan',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 0.0),
                            child: program.gambar.isNotEmpty
                                ? AspectRatio(
                                    aspectRatio: 2 / 3,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        program.gambar.startsWith('http')
                                            ? program.gambar
                                            : 'https://example.com${program.gambar}',
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (
                                              context,
                                              error,
                                              stackTrace,
                                            ) => Container(
                                              color: const Color(0xFF1E1E1E),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.radio,
                                                  size: 80,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                      ),
                                    ),
                                  )
                                : AspectRatio(
                                    aspectRatio: 2 / 3,
                                    child: Container(
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
}
