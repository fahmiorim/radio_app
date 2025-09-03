import 'package:intl/intl.dart';
import '../config/app_api_config.dart';

class Artikel {
  final int id;
  final String title;
  final String slug;
  final String content;
  final String excerpt;
  final String image;
  final DateTime? publishedAt;
  final String user;
  final DateTime? updatedAt;

  Artikel({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.excerpt,
    required this.image,
    required this.publishedAt,
    required this.user,
    this.updatedAt,
  });

  factory Artikel.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) =>
        v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;

    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return Artikel(
      id: _toInt(json['id']),
      title: (json['title'] ?? json['judul'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      excerpt: (json['excerpt'] ?? '').toString(),
      image: (json['image'] ?? json['gambar'] ?? '').toString(),
      publishedAt: _toDate(json['published_at'] ?? json['publishedAt']),
      user: (json['user'] ?? 'Admin').toString(),
      updatedAt: _toDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'slug': slug,
    'content': content,
    'excerpt': excerpt,
    'image': image,
    'published_at': publishedAt?.toIso8601String(),
    'user': user,
    'updated_at': updatedAt?.toIso8601String(),
  };

  String get formattedDate {
    if (publishedAt == null) return '-';
    return DateFormat("EEEE, dd MMMM yyyy", "id_ID").format(publishedAt!);
  }

  String get contentPlain => _stripHtml(content);
  String get excerptPlain => _stripHtml(excerpt);

  String get gambarUrl {
    final raw = image.trim();
    if (raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return _appendV(raw, updatedAt);
    }

    final base = AppApiConfig.assetBaseUrl;
    if (raw.startsWith('/')) {
      return _appendV('$base$raw', updatedAt);
    }
    return _appendV('$base/storage/$raw', updatedAt);
  }
}

String _stripHtml(String s) => s.replaceAll(RegExp(r'<[^>]*>'), '').trim();

String _appendV(String url, DateTime? v) {
  if (v == null) return url;
  final tag = v.millisecondsSinceEpoch;
  return url.contains('?') ? '$url&v=$tag' : '$url?v=$tag';
}
