import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart'; // cukup ini saja
import 'package:html/dom.dart' as dom;
import 'package:url_launcher/url_launcher.dart';
import '../../../models/artikel_model.dart';

class ArtikelDetailScreen extends StatelessWidget {
  final Artikel artikel;

  const ArtikelDetailScreen({super.key, required this.artikel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Artikel'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul Artikel
            Text(
              artikel.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // Penulis & Tanggal
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  artikel.user,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  artikel.formattedDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Gambar Utama
            if (artikel.gambarUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  artikel.gambarUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Konten Artikel (HTML)
            if (artikel.content.isNotEmpty)
              Html(
                data: artikel.content,
                style: {
                  "body": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(16.0),
                    lineHeight: LineHeight(1.6),
                    textAlign: TextAlign.justify,
                    color: Colors.white, // sesuaikan untuk dark theme
                  ),
                  "p": Style(
                    margin: Margins.only(bottom: 16),
                    fontSize: FontSize(16.0),
                  ),
                  "img": Style(
                    width: Width(double.infinity),
                    height: Height(200),
                    alignment: Alignment.center,
                    margin: Margins.only(top: 8, bottom: 16),
                  ),
                  "b": Style(fontWeight: FontWeight.bold),
                  "span": Style(fontSize: FontSize(16.0)),
                },
                onLinkTap:
                    (
                      String? url,
                      Map<String, String> attributes,
                      dom.Element? element,
                    ) async {
                      if (url == null) return;
                      final uri = Uri.tryParse(url);
                      if (uri == null) return;

                      try {
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tidak dapat membuka tautan: $url'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Terjadi kesalahan: ${e.toString()}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              ),
          ],
        ),
      ),
    );
  }
}
