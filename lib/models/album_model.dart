import '../config/app_api_config.dart';

String _resolveAssetUrl(String path) {
  final p = path.trim();
  if (p.isEmpty) return '';
  if (p.startsWith('http://') || p.startsWith('https://')) return p;

  var base = AppApiConfig.assetBaseUrl.trim();
  while (base.endsWith('/')) {
    base = base.substring(0, base.length - 1);
  }

  if (p.startsWith('/')) return '$base$p';
  return '$base/$p';
}

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
    final u = json['user'];
    final String userString = u is Map
        ? (u['name']?.toString() ?? 'Unknown')
        : (u?.toString() ?? 'Unknown');

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return AlbumModel(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] as String?)?.trim() ?? 'Untitled Album',
      slug: (json['slug'] as String?)?.trim() ?? '',
      description: json['description'] as String?,
      coverImage:
          (json['cover_image_url'] as String?)?.trim() ??
          (json['cover_image'] as String?)?.trim() ??
          '',
      isPublic:
          (json['is_public'] == true) ||
          (json['is_public'] == 1) ||
          (json['is_public'] == '1'),
      user: userString,
      photosCount: parseInt(json['photos_count']),
    );
  }

  String get title => name;

  String get coverUrl {
    if (coverImage.isEmpty) return '';

    // If it's already a full URL, return as is
    if (coverImage.startsWith('http')) {
      return coverImage;
    }

    // If it's a path starting with /storage, construct full URL
    if (coverImage.startsWith('/storage/')) {
      return 'http://192.168.1.7:8000$coverImage';
    }

    // For any other case, use _resolveAssetUrl
    return _resolveAssetUrl(coverImage);
  }

  List<String> get photos => List.generate(photosCount ?? 0, (_) => '');

  int get totalPhotos => photosCount ?? 0;
}

class PhotoModel {
  final int id;
  final int albumId;
  final String image;
  final int? order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PhotoModel({
    required this.id,
    required this.albumId,
    required this.image,
    this.order,
    this.createdAt,
    this.updatedAt,
  });

  String get url {
    if (image.isEmpty) {
      return '';
    }

    // Handle case where image is already a full URL
    if (image.startsWith('http')) {
      return image;
    }

    // For any other case, use the _resolveAssetUrl which will handle the base URL
    return _resolveAssetUrl(image);
  }

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => (v is int) ? v : int.tryParse('$v') ?? 0;
    DateTime? asDate(dynamic v) =>
        (v == null) ? null : DateTime.tryParse(v.toString());

    // Ensure we get the image URL correctly
    String? imageUrl = (json['image'] as String?)?.trim();

    // Always use the imageUrl as is, and let the url getter handle the URL construction
    return PhotoModel(
      id: asInt(json['id']),
      albumId: asInt(json['album_id']),
      image: imageUrl ?? '',
      order: (json['order'] is int)
          ? json['order'] as int
          : int.tryParse('${json['order']}'),
      createdAt: asDate(json['created_at']),
      updatedAt: asDate(json['updated_at']),
    );
  }
}

class AlbumDetailModel {
  final String name;
  final AlbumModel album;
  final List<PhotoModel> photos;

  AlbumDetailModel({
    required this.name,
    required this.album,
    required this.photos,
  });

  factory AlbumDetailModel.fromJson(Map<String, dynamic> json) {
    try {
      // Handle the case where the response has a 'data' field
      final Map<String, dynamic> data = json['data'] is Map
          ? Map<String, dynamic>.from(json['data'])
          : Map<String, dynamic>.from(json);

      // Extract album data - prefer the nested 'album' object if available
      final Map<String, dynamic> albumData = data['album'] is Map
          ? Map<String, dynamic>.from(data['album'])
          : data;

      // Handle photos array
      List<PhotoModel> photos = [];
      if (data['photos'] is List) {
        photos = (data['photos'] as List)
            .whereType<Map>()
            .map((e) => PhotoModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      final album = AlbumModel.fromJson(albumData);
      final name = (data['name'] as String?)?.trim() ?? album.name;

      return AlbumDetailModel(name: name, album: album, photos: photos);
    } catch (e) {
      rethrow;
    }
  }
}
