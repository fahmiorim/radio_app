import '../config/app_api_config.dart';

class Penyiar {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String avatar;
  final bool? isActive;
  final List<dynamic>? programSiaran;

  Penyiar({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.avatar,
    this.isActive,
    this.programSiaran = const [],
  });

  factory Penyiar.fromJson(Map<String, dynamic> json) {
    return Penyiar(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      avatar: (json['avatar'] ?? '').toString(),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      programSiaran: json['program_siaran'] != null 
          ? (json['program_siaran'] as List).toList()
          : null,
    );
  }

  String get avatarUrl {
    final raw = avatar.trim();
    if (raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    final base = AppApiConfig.assetBaseUrl;
    if (raw.startsWith('/')) return '$base$raw';
    return '$base/storage/$raw';
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  return int.tryParse('$v') ?? 0;
}
