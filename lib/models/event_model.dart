import 'package:intl/intl.dart';
import '../config/app_api_config.dart';

class Event {
  final int id;
  final String judul;
  final String? user;
  final String? penyiarName;
  final DateTime tanggal;
  final String deskripsi;
  final String gambar;
  final String status;
  final String tipe;
  final DateTime? updatedAt;

  Event({
    required this.id,
    required this.judul,
    this.user,
    this.penyiarName,
    required this.tanggal,
    required this.deskripsi,
    required this.gambar,
    required this.status,
    required this.tipe,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic v) =>
        v is int ? v : int.tryParse((v ?? '').toString()) ?? 0;

    DateTime _parseDate(dynamic v) {
      final s = (v ?? '').toString();
      if (s.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(s);
      } catch (_) {
        return DateTime.now();
      }
    }

    String _stripHtml(dynamic v) {
      final s = (v ?? '').toString();
      return s.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    }

    DateTime? _parseDateNullable(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return Event(
      id: _parseInt(json['id']),
      judul: (json['judul'] ?? json['title'] ?? '').toString(),
      user: json['user'] ?? json['penyiarName'] ?? json['author'] ?? 'Tidak ada data',
      tanggal: _parseDate(json['tanggal'] ?? json['date']),
      deskripsi: _stripHtml(json['deskripsi'] ?? json['content']),
      gambar: (json['gambar'] ?? json['image'] ?? json['cover'] ?? '')
          .toString(),
      status: (json['status'] ?? '').toString(),
      tipe: (json['tipe'] ?? json['type'] ?? '').toString(),
      updatedAt: _parseDateNullable(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'judul': judul,
    'user': user,
    'tanggal': tanggal.toIso8601String(),
    'deskripsi': deskripsi,
    'gambar': gambar,
    'status': status,
    'tipe': tipe,
    'updated_at': updatedAt?.toIso8601String(),
  };

  String get formattedTanggal =>
      DateFormat("EEEE, d MMMM yyyy", "id_ID").format(tanggal);

  String get gambarUrl {
    final raw = gambar.trim();
    if (raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return _appendV(raw, updatedAt);
    }

    final base = AppApiConfig.assetBaseUrl;
    if (raw.startsWith('/')) {
      return _appendV('$base$raw', updatedAt);
    }
    return _appendV('$base/storage/$raw', updatedAt);
  }
}

String _appendV(String url, DateTime? v) {
  if (v == null) return url;
  final tag = v.millisecondsSinceEpoch;
  return url.contains('?') ? '$url&v=$tag' : '$url?v=$tag';
}
