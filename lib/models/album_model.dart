class AlbumModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String coverImage;
  final bool isPublic;
  final String user;
  final int? photosCount;

  AlbumModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.coverImage,
    required this.isPublic,
    required this.user,
    required this.photosCount,
  });

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    // Handle user field which might be a Map or String
    final user = json['user'];
    final String userString = user is Map ? (user['name'] ?? 'Unknown') : user?.toString() ?? 'Unknown';
    
    // Safely parse photos_count
    int? parsePhotosCount(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    return AlbumModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Untitled Album',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      coverImage: json['cover_image'] as String? ?? '',
      isPublic: json['is_public'] as bool? ?? true,
      user: userString,
      photosCount: parsePhotosCount(json['photos_count']),
    );
  }

  // For backward compatibility
  String get title => name;
  String get coverUrl => coverImage;
  
  // For compatibility with existing code that expects photos list
  List<String> get photos => List.generate(photosCount ?? 0, (index) => '');
}
