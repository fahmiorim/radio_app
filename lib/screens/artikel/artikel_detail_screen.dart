import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../models/artikel_model.dart';
import '../../../providers/artikel_provider.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/loading/loading_widget.dart';

class ArtikelDetailScreen extends StatefulWidget {
  final String artikelSlug;
  const ArtikelDetailScreen({super.key, required this.artikelSlug});

  @override
  State<ArtikelDetailScreen> createState() => _ArtikelDetailScreenState();
}

class _ArtikelDetailScreenState extends State<ArtikelDetailScreen> {
  Artikel? _artikel;
  String? _error;
  bool _loading = true;

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prov = context.read<ArtikelProvider>();
      // Pastikan ini memanggil endpoint DETAIL dan mengembalikan Artikel dengan content terisi
      final detail = await prov.fetchArtikelBySlug(widget.artikelSlug);
      setState(() => _artikel = detail);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final artikel = _artikel;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(child: LoadingWidget()),
      );
    }

    if (_error != null || artikel == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: CustomAppBar.transparent(title: 'Error'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Terjadi kesalahan',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _load(force: true),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final content = (artikel.content).trim();
    final isEmptyContent =
        content.isEmpty || content == '<p></p>' || content == '<div></div>';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: CustomAppBar.transparent(title: artikel.title),
      body: RefreshIndicator(
        onRefresh: () => _load(force: true),
        color: AppColors.primary,
        backgroundColor: AppColors.backgroundDark,
        child: Stack(
          children: [
            // Background
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
                      color: Colors.white,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
                        artikel.publishedAt != null
                            ? DateFormat(
                                'dd MMMM yyyy',
                                'id_ID',
                              ).format(artikel.publishedAt!)
                            : '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Gambar
                  if (artikel.image.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        artikel.image,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
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
                        "a": Style(textDecoration: TextDecoration.underline),
                        "img": Style(margin: Margins.symmetric(vertical: 16)),
                      },
                      onLinkTap:
                          (
                            String? url,
                            Map<dynamic, String> attributes,
                            dom.Element? element,
                          ) {
                            if (url == null) return;
                            final uri = Uri.tryParse(url);
                            if (uri != null) {
                              launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tautan tidak valid'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                    )
                  else
                    const Text(
                      'Konten belum tersedia.',
                      style: TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
