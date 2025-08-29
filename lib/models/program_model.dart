// lib/models/program_model.dart
import '../config/app_api_config.dart';

class Program {
  final int id;
  final String namaProgram;
  final String deskripsi;
  final String gambar; // raw dari API (bisa relatif)
  final String status;
  final String? penyiar;
  final String? jadwal;
  final String? penyiarName;
  final DateTime? updatedAt; // opsional, untuk cache-busting kalau perlu

  Program({
    required this.id,
    required this.namaProgram,
    required this.deskripsi,
    required this.gambar,
    required this.status,
    this.penyiar,
    this.jadwal,
    this.penyiarName,
    this.updatedAt,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    String stripHtml(dynamic v) {
      final s = (v ?? '').toString();
      return s.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    }

    int parseInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

    DateTime? parseDT(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v);
        } catch (_) {}
      }
      return null;
    }

    return Program(
      id: parseInt(json['id']),
      namaProgram:
          (json['nama_program'] ?? json['title'] ?? 'Program Tanpa Nama')
              .toString(),
      deskripsi: stripHtml(json['deskripsi']),
      gambar: (json['gambar'] ?? json['cover'] ?? json['image'] ?? '')
          .toString(),
      status: (json['status'] ?? 'aktif').toString(),
      penyiar: (json['penyiar'] ?? json['host'])?.toString(),
      jadwal: json['jadwal']?.toString(),
      penyiarName:
          (json['penyiarName'] ?? json['penyiar_name'] ?? json['penyiar'])
              ?.toString(),
      updatedAt: parseDT(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama_program': namaProgram,
    'deskripsi': deskripsi,
    'gambar': gambar,
    'status': status,
    'penyiar': penyiar,
    'jadwal': jadwal,
    'penyiarName': penyiarName,
    'updated_at': updatedAt?.toIso8601String(),
  };

  /// Full URL siap pakai untuk UI. Jika kosong → return '' (biar UI tampilkan placeholder).
  String get gambarUrl {
    final raw = gambar.trim();
    if (raw.isEmpty) return '';

    // Sudah full URL
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return _appendV(raw, updatedAt);
    }

    final base = AppApiConfig.assetBaseUrl; // <-- PAKAI ASSET_BASE_URL
    // Relatif dengan slash depan: "/storage/..." → base + raw
    if (raw.startsWith('/')) {
      return _appendV('$base$raw', updatedAt);
    }
    // Relatif tanpa slash: "gambar.jpg" atau "program/cover.jpg" → asumsikan /storage/
    return _appendV('$base/storage/$raw', updatedAt);
  }
}

String _appendV(String url, DateTime? v) {
  if (v == null) return url;
  final tag = v.millisecondsSinceEpoch;
  return url.contains('?') ? '$url&v=$tag' : '$url?v=$tag';
}
