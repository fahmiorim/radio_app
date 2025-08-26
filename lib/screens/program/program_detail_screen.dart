import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import '../../models/program_model.dart';
import '../../services/program_service.dart';
import '../../config/app_colors.dart';
import '../../widgets/mini_player.dart';

class ProgramDetailScreen extends StatefulWidget {
  final int programId;

  const ProgramDetailScreen({super.key, required this.programId});

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  final ProgramService _programService = ProgramService();
  bool _isLoading = true;
  Program? _program;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchProgramDetails();
  }

  Future<void> _fetchProgramDetails() async {
    try {
      final program = await _programService.fetchProgramById(widget.programId);
      if (mounted) {
        setState(() {
          _program = program;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat detail program';
          _isLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _program?.namaProgram ?? 'Detail Program',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: AppColors.surface,
                blurRadius: 4,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    )
                  : _program == null
                      ? const Center(
                          child: Text(
                            'Program tidak ditemukan',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : CustomScrollView(
                          slivers: [
                            // Header with poster image
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 8.0, // Menggunakan nilai fixed yang lebih kecil
                                ),
                                child: _program!.gambar.isNotEmpty
                                    ? AspectRatio(
                                        aspectRatio: 3 / 4, // Standard portrait ratio
                                        child: Image.network(
                                          _program!.gambar,
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                                color: AppColors.surface,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.radio,
                                                    size: 80,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                        ),
                                      )
                                    : Container(
                                        height:
                                            MediaQuery.of(context).size.width *
                                            1.33, // 3:4 ratio
                                        color: AppColors.surface,
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

                            // Content
                            SliverToBoxAdapter(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF121212),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(30),
                                    topRight: Radius.circular(30),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Program Title
                                    Text(
                                      _program!.namaProgram,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        height: 1.2,
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Host Name
                                    if (_program!.penyiarName?.isNotEmpty == true)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person_outline,
                                            color: AppColors.textSecondary,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _program!.penyiarName!,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),

                                    const SizedBox(height: 24),

                                    // Schedule
                                    if (_program!.jadwal?.isNotEmpty == true)
                                      _buildInfoCard(
                                        context,
                                        title: 'Jadwal Siaran',
                                        content: _program!.jadwal!,
                                        icon: Icons.schedule,
                                      ),

                                    const SizedBox(height: 16),

                                    // Description
                                    if (_program!.deskripsi.isNotEmpty)
                                      _buildInfoCard(
                                        context,
                                        title: 'Tentang Program',
                                        content: _parseHtmlString(_program!.deskripsi),
                                        icon: Icons.info_outline,
                                      ),

                                    const SizedBox(height: 30),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
