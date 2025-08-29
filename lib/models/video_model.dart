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
    final rawUrl = (json['youtube_url'] as String?) ?? '';
    String ytId = (json['youtube_id'] as String?) ?? '';
    if (ytId.isEmpty && rawUrl.isNotEmpty) {
      ytId = _extractYouTubeId(rawUrl) ?? '';
    }

    final created =
        _parseDate(json['created_at']) ??
        _parseDate(json['published_at']) ??
        DateTime.now();

    return VideoModel(
      id: _asInt(json['id']),
      title: (json['title'] as String?)?.trim() ?? 'No Title',
      description: (json['description'] as String?) ?? '',
      youtubeUrl: rawUrl,
      youtubeId: ytId,
      thumbnailUrl: (json['thumbnail_url'] as String?) ?? '',
      duration: json['duration'] as String?,
      embedHtml: (json['embed_html'] as String?) ?? '',
      isFeatured:
          json['is_featured'] == true ||
          json['is_featured'] == 1 ||
          json['is_featured'] == '1',
      user: (json['user'] as String?) ?? 'Unknown',
      createdAt: created,
    );
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

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

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
