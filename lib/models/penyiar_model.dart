import '../config/app_api_config.dart';

class Penyiar {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final bool isActive;
  final List<dynamic> programSiaran;

  Penyiar({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.isActive,
    required this.programSiaran,
  });

  factory Penyiar.fromJson(Map<String, dynamic> json) {
    return Penyiar(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'] ?? '',
      avatar: json['avatar'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      programSiaran: json['program_siaran'] ?? [],
    );
  }

  String get avatarUrl => "${AppApiConfig.baseUrlStorage}/$avatar";
}
