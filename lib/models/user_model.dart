import '../config/app_api_config.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? avatar;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.avatar,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get avatarUrl {
    final raw = avatar?.trim();
    if (raw == null || raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return _appendVersion(raw);
    }

    final base = AppApiConfig.assetBaseUrl;
    final url = raw.startsWith('/') ? '$base$raw' : '$base/storage/$raw';

    return _appendVersion(url);
  }

  String _appendVersion(String url) {
    final v = updatedAt.millisecondsSinceEpoch;
    return url.contains('?') ? '$url&v=$v' : '$url?v=$v';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Tidak ada nama',
      email: json['email'] ?? 'Tidak ada email',
      phone: json['phone'],
      address: json['address'],
      avatar: json['avatar'],
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'avatar': avatar, // simpan raw
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
