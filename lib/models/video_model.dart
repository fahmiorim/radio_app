import '../config/app_api_config.dart';

class VideoModel {
  final int id;
  final String title;
  final String description;
  final String youtubeUrl;
  final String youtubeId;
  final String thumbnailUrl;
  final String? duration;
  final String embedHtml;
  final bool isFeatured;
  final String user;
  final DateTime createdAt;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeUrl,
    required this.youtubeId,
    required this.thumbnailUrl,
    this.duration,
    required this.embedHtml,
    required this.isFeatured,
    required this.user,
    required this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    try {
      // Handle null safety and type conversion for all fields
      final rawUrl = _parseString(json['youtube_url']);
      String ytId = _parseString(json['youtube_id']);

      if (ytId.isEmpty && rawUrl.isNotEmpty) {
        ytId = _extractYouTubeId(rawUrl) ?? '';
      }

      final created =
          _parseDate(json['created_at']) ??
          _parseDate(json['published_at']) ??
          DateTime.now();

      return VideoModel(
        id: _parseInt(json['id']),
        title: _parseString(json['title']).trim().isNotEmpty
            ? _parseString(json['title']).trim()
            : 'No Title',
        description: _parseString(json['description']),
        youtubeUrl: rawUrl,
        youtubeId: ytId,
        thumbnailUrl: _parseString(json['thumbnail_url']),
        duration: _parseString(json['duration']),
        embedHtml: _parseString(json['embed_html']),
        isFeatured:
            json['is_featured'] == true ||
            json['is_featured'] == 1 ||
            _parseString(json['is_featured']) == '1',
        user: _parseString(json['user']).isNotEmpty
            ? _parseString(json['user'])
            : 'Unknown',
        createdAt: created,
      );
    } catch (e) {
      rethrow;
    }
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    try {
      return value.toString();
    } catch (e) {
      return '';
    }
  }

  static int _parseInt(dynamic value) {
    try {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'youtube_url': youtubeUrl,
      'youtube_id': youtubeId,
      'thumbnail_url': thumbnailUrl,
      'duration': duration,
      'embed_html': embedHtml,
      'is_featured': isFeatured,
      'user': user,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get safeThumbnailUrl {
    final thumb = thumbnailUrl.trim();
    if (thumb.isNotEmpty) return _resolve(thumb);
    if (youtubeId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';
    }
    return '';
  }

  String get watchUrl => youtubeId.isNotEmpty
      ? 'https://www.youtube.com/watch?v=$youtubeId'
      : youtubeUrl;

  String get embedUrl =>
      youtubeId.isNotEmpty ? 'https://www.youtube.com/embed/$youtubeId' : '';

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static String? _extractYouTubeId(String url) {
    final reg = RegExp(
      r'(?:v=|/videos/|embed/|youtu\.be/|/shorts/)([A-Za-z0-9_-]{11})',
      caseSensitive: false,
    );
    final m = reg.firstMatch(url);
    return m != null && m.groupCount >= 1 ? m.group(1) : null;
  }

  static String _resolve(String path) {
    final p = path.trim();
    if (p.isEmpty) return '';
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    final base = AppApiConfig.assetBaseUrl;
    if (p.startsWith('/')) return '$base$p';
    return '$base/$p';
  }

  String get videoUrl => youtubeUrl;
}
