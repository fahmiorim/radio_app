import '../config/app_api_config.dart';

class Program {
  final int id;
  final String namaProgram;
  final String deskripsi;
  final String gambar;
  final String status;
  final String? penyiar;
  final String? jadwal;
  final String? penyiarName;

  Program({
    required this.id,
    required this.namaProgram,
    required this.deskripsi,
    required this.gambar,
    required this.status,
    this.penyiar,
    this.jadwal,
    this.penyiarName,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    // Handle both API response formats
    final deskripsi = json['deskripsi'] is String 
        ? (json['deskripsi'] as String).replaceAll(RegExp(r'<[^>]*>'), '').trim() 
        : '';
        
    return Program(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      namaProgram: json['nama_program']?.toString() ?? 'Program Tanpa Nama',
      deskripsi: deskripsi,
      gambar: json['gambar']?.toString() ?? '',
      status: json['status']?.toString() ?? 'aktif',
      penyiar: json['penyiar']?.toString(),
      jadwal: json['jadwal']?.toString(),
      penyiarName: json['penyiarName']?.toString() ?? json['penyiar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_program': namaProgram,
      'deskripsi': deskripsi,
      'gambar': gambar,
      'status': status,
      'penyiar': penyiar,
      'jadwal': jadwal,
      'penyiarName': penyiarName,
    };
  }

  /// Get the image URL with fallback
  String get gambarUrl {
    // Return default image if no image is set
    if (gambar.isEmpty) {
      return 'assets/default_program.png';
    }

    // If the image URL is already a full URL, return it as is
    if (gambar.startsWith('http')) {
      return gambar;
    }

    // Handle different URL formats
    if (gambar.startsWith('/storage/')) {
      return '${AppApiConfig.baseUrl}$gambar';
    }

    // Default case - prepend base URL
    return '${AppApiConfig.baseUrl}/$gambar'.replaceAll(
      RegExp(r'(?<!:)/+'),
      '/',
    );
  }
}
