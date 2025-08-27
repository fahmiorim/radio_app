import 'album_model.dart';

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
    final data = json is Map<String, dynamic> ? json : json['data'] as Map<String, dynamic>;
    
    // Handle case when photos is a string (e.g., "Tidak ada foto")
    List<PhotoModel> photosList = [];
    if (data['photos'] is List) {
      photosList = (data['photos'] as List).map((photo) => PhotoModel.fromJson(photo as Map<String, dynamic>)).toList();
    }
    // Else, photosList remains empty

    return AlbumDetailModel(
      name: data['name'] as String? ?? '',
      album: AlbumModel.fromJson(data['album'] as Map<String, dynamic>),
      photos: photosList,
    );
  }
}

class PhotoModel {
  final int id;
  final int albumId;
  final String image;
  final int? order;
  final DateTime createdAt;
  final DateTime updatedAt;

  PhotoModel({
    required this.id,
    required this.albumId,
    required this.image,
    this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  String get url => image; // For backward compatibility

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] as int,
      albumId: json['album_id'] as int,
      image: json['image'] as String,
      order: json['order'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
