import 'package:intl/intl.dart';
import '../config/app_api_config.dart';

class Program {
  final int id;
  final String namaProgram;
  final String deskripsi;
  final String gambar;
  final String status;
  final String? penyiarName;

  Program({
    required this.id,
    required this.namaProgram,
    required this.deskripsi,
    required this.gambar,
    required this.status,
    this.penyiarName,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'] ?? 0,
      namaProgram: json['nama_program'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      gambar: json['gambar'] ?? '',
      status: json['status'] ?? '',
      penyiarName: json['penyiarName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nama_program": namaProgram,
      "deskripsi": deskripsi,
      "gambar": gambar,
      "status": status,
      "penyiarName": penyiarName,
    };
  }

  /// ✅ fallback kalau gambar kosong
  String get gambarUrl {
    // Return default image if no image is set
    if (gambar.isEmpty) {
      return 'assets/default_program.png';
    }

    // If the image URL is already a full URL, return it as is
    if (gambar.startsWith('http')) {
      return gambar;
    }

    // If it's a relative path, prepend the base URL
    return '${AppApiConfig.baseUrl}/$gambar'.replaceAll(
      RegExp(r'(?<!:)/+'),
      '/',
    );
  }
}
