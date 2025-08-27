import 'package:intl/intl.dart';

class Artikel {
  final int id;
  final String title;
  final String slug;
  final String content;
  final String excerpt;
  final String image;
  final DateTime? publishedAt; // ✅ konsisten DateTime
  final String user;

  Artikel({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.excerpt,
    required this.image,
    required this.publishedAt,
    required this.user,
  });

  factory Artikel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;

    // published_at dari API itu String -> parse ke DateTime
    if (json['published_at'] != null) {
      parsedDate = DateTime.tryParse(json['published_at'].toString());
    }

    return Artikel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      content: json['content'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      image: json['image'] as String? ?? '',
      publishedAt: parsedDate,
      user: json['user'] as String? ?? 'Admin',
    );
  }

  String get formattedDate {
    if (publishedAt == null) return "-";
    return DateFormat("EEEE, dd MMMM yyyy", "id_ID").format(publishedAt!);
  }

  String get gambarUrl => image;
}
