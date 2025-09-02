import '../config/app_api_config.dart';

class ProgramModel {
  final int id;
  final String namaProgram;
  final String gambar; // bisa absolute URL dari backend
  final String? jadwal; // ada di /semua & /{id}
  final String? deskripsiHtml; // ada di /{id}

  ProgramModel({
    required this.id,
    required this.namaProgram,
    required this.gambar,
    this.jadwal,
    this.deskripsiHtml,
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    return ProgramModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      namaProgram: json['nama_program']?.toString() ?? '',
      gambar: json['gambar']?.toString() ?? '',
      jadwal: json['jadwal']?.toString(),
      deskripsiHtml: json['deskripsi']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama_program': namaProgram,
    'gambar': gambar,
    'jadwal': jadwal,
    'deskripsi': deskripsiHtml,
  };

  /// Normalisasi URL gambar kalau backend kirim path relatif.
  String get gambarUrl {
    if (gambar.isEmpty) return '';
    if (gambar.startsWith('http://') || gambar.startsWith('https://')) {
      return gambar;
    }
    final base = AppApiConfig.assetBaseUrl;
    return gambar.startsWith('/') ? '$base$gambar' : '$base/storage/$gambar';
  }
}
