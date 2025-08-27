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
    return VideoModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String? ?? '',
      youtubeUrl: json['youtube_url'] as String? ?? '',
      youtubeId: json['youtube_id'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      duration: json['duration'] as String?,
      embedHtml: json['embed_html'] as String? ?? '',
      isFeatured: json['is_featured'] as bool? ?? false,
      user: json['user'] as String? ?? 'Unknown',
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  // For backward compatibility
  String get videoUrl => youtubeUrl;
}
