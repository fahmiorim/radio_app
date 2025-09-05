import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:radio_odan_app/providers/artikel_provider.dart';
import 'package:radio_odan_app/widgets/app_bar.dart';
import 'package:radio_odan_app/widgets/loading/loading_widget.dart';
import 'package:radio_odan_app/widgets/mini_player.dart';

class ArtikelDetailScreen extends StatefulWidget {
  final String artikelSlug;
  const ArtikelDetailScreen({super.key, required this.artikelSlug});

  @override
  State<ArtikelDetailScreen> createState() => _ArtikelDetailScreenState();
}

class _ArtikelDetailScreenState extends State<ArtikelDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  @override
  void didUpdateWidget(covariant ArtikelDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artikelSlug != widget.artikelSlug) {
      _loadArticle();
    }
  }

  Future<void> _loadArticle() async {
    final provider = context.read<ArtikelProvider>();
    provider.clearError();
    provider.clearSelectedArtikel();
    await provider.fetchArtikelBySlug(widget.artikelSlug);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ArtikelProvider>(
      builder: (context, provider, _) {
        final artikel = provider.selectedArtikel;
        final error = provider.error;
        final isLoading = provider.isLoadingDetail;

        if (isLoading) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: LoadingWidget()),
          );
        }

        if (error != null || artikel == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: CustomAppBar.transparent(title: 'Error'),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    error ?? 'Artikel tidak ditemukan',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadArticle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        final content = artikel.content.trim();
        final isEmptyContent =
            content.isEmpty || content == '<p></p>' || content == '<div></div>';

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: CustomAppBar.transparent(title: artikel.title),
          body: RefreshIndicator(
            onRefresh: _loadArticle,
            color: Theme.of(context).primaryColor,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: Stack(
              children: [
                // Background with gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -50,
                          right: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -30,
                          left: -30,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 100,
                          left: 100,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul
                      Text(
                        artikel.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Penulis & Tanggal
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            artikel.user,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            artikel.formattedDate,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Gambar header
                      if (artikel.gambarUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            artikel.gambarUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              color: Colors.grey[800],
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Konten
                      if (!isEmptyContent)
                        Html(
                          data: content,
                          style: {
                            "html": Style(
                              color: Colors.white,
                              fontSize: FontSize(16.0),
                              lineHeight: LineHeight(1.6),
                            ),
                            "body": Style(
                              color: Colors.white,
                              fontSize: FontSize(16.0),
                              lineHeight: LineHeight(1.6),
                            ),
                            "p": Style(margin: Margins.only(bottom: 16)),
                            "h1": Style(
                              color: Colors.white,
                              fontSize: FontSize(24.0),
                              fontWeight: FontWeight.bold,
                              margin: Margins.only(top: 24, bottom: 16),
                            ),
                            "h2": Style(
                              color: Colors.white,
                              fontSize: FontSize(20.0),
                              fontWeight: FontWeight.bold,
                              margin: Margins.only(top: 20, bottom: 14),
                            ),
                            "a": Style(
                              textDecoration: TextDecoration.underline,
                            ),
                            "img": Style(
                              margin: Margins.symmetric(vertical: 16),
                            ),
                          },
                          onLinkTap:
                              (
                                String? url,
                                Map<String, String> attributes,
                                dom.Element? element,
                              ) {
                                if (url == null) return;
                                final uri = Uri.tryParse(url);
                                if (uri != null) {
                                  launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Tautan tidak valid'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                        )
                      else
                        const Text(
                          'Konten belum tersedia.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),

                // Mini Player
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: MiniPlayer(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
