import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:radio_odan_app/providers/program_provider.dart';
import 'package:radio_odan_app/widgets/common/app_bar.dart';
import 'package:radio_odan_app/widgets/common/mini_player.dart';
import 'package:radio_odan_app/widgets/common/app_background.dart';

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
      // Use addPostFrameCallback to ensure we're not in the build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadProgramData();
      });
    }
  }

  Future<void> _loadProgramData() async {
    final prov = Provider.of<ProgramProvider>(context, listen: false);
    final programId = ModalRoute.of(context)?.settings.arguments as int?;

    if (programId == null) return;

    try {
      // Always fetch fresh data when the screen loads
      await prov.fetchDetail(programId);
    } catch (_) {
      // Error will be handled by the UI through the provider's error state
      debugPrint('Error loading program details');
    }
  }

  Widget _buildInfoCard(String title, String value, {IconData? icon}) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Row(
                children: [
                  Icon(
                    icon,
                    color: theme.colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 8),
            value.trim().isNotEmpty
                ? Html(
                    data: value,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: FontSize(14.0),
                        lineHeight: LineHeight(1.5),
                      ),
                      "p": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.only(bottom: 8.0),
                      ),
                      "a": Style(
                        color: theme.colorScheme.primary,
                        textDecoration: TextDecoration.none,
                      ),
                      "strong": Style(fontWeight: FontWeight.bold),
                      "em": Style(fontStyle: FontStyle.italic),
                    },
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _detailImage(String url) {
    // Rasio 2:3 sesuai kebutuhan
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url.isEmpty
            ? Container(
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                  child: Icon(
                    Icons.radio,
                    size: 80,
                    color: Theme.of(context).colorScheme.onSurface,
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
                  color: Theme.of(context).colorScheme.surface,
                  child: Center(
                    child: Icon(
                      Icons.radio,
                      size: 80,
                      color: Theme.of(context).colorScheme.onSurface,
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
      builder: (context, prov, _) {
        final program = prov.selectedProgram;
        final isLoading = prov.isLoadingDetail && program == null;
        final error = prov.detailError;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: CustomAppBar.transparent(
            context: context,
            title: program?.namaProgram ?? 'Detail Program',
            titleColor: Theme.of(context).colorScheme.onSurface,
            iconColor: Theme.of(context).colorScheme.onSurface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  prov.clearSelected();
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
          body: Stack(
            children: [
              const AppBackground(),

              // Content states
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (error != null && program == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Gagal memuat detail program',
                          style:
                              Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
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
                      Icon(
                        Icons.radio,
                        size: 64,
                        color:
                            Theme.of(context).colorScheme.onBackground,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Program tidak ditemukan',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              else
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _detailImage(program.gambarUrl)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Text(
                                program.namaProgram,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(height: 1.2),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // (Opsional) Penyiar — hanya tampilkan jika field nanti ditambahkan
                            // if (program.penyiarName != null && program.penyiarName!.isNotEmpty) ...
                            const SizedBox(height: 24),

                            // Deskripsi (strip HTML aman)
                            if ((program.deskripsiHtml ?? '').isNotEmpty)
                              _buildInfoCard(
                                'Tentang Program',
                                program.deskripsiHtml!,
                                icon: Icons.info_outline,
                              ),

                            // Jadwal
                            if ((program.jadwal ?? '').isNotEmpty)
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

  // _bubble method removed - using AppTheme.bubble instead
}
