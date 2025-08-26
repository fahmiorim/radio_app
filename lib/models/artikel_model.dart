import 'package:intl/intl.dart';

class Artikel {
  final int id;
  final String title;
  final String slug;
  final String content;
  final String image;
  final bool isPublished;
  final DateTime? publishedAt;
  final String user;

  Artikel({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.image,
    required this.isPublished,
    this.publishedAt,
    required this.user,
  });

  factory Artikel.fromJson(Map<String, dynamic> json) {
    return Artikel(
      id: json['id'],
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      content: json['content'] ?? '',
      image: json['image'] ?? '',
      isPublished: json['is_published'] == 1 || json['is_published'] == true,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'])
          : null,
      user: json['user'] ?? "Tidak ada data",
    );
  }

  String get formattedDate {
    if (publishedAt == null) return "-";
    return DateFormat("EEEE, dd MMMM yyyy", "id_ID").format(publishedAt!);
  }

  String get gambarUrl {
    // Return empty string if no image
    if (image.isEmpty) return '';
    
    // If the image URL is already a full URL, return it as is
    if (image.startsWith('http')) {
      return image;
    }
    
    // Return the image path as is (assuming it's already correct from the API)
    return image;
  }
}
