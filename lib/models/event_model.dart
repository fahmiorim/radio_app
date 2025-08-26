import 'package:intl/intl.dart';

class Event {
  final int id;
  final String judul;
  final String user;
  final DateTime tanggal;
  final String deskripsi;
  final String gambar;
  final String status;
  final String tipe;

  Event({
    required this.id,
    required this.judul,
    required this.user,
    required this.tanggal,
    required this.deskripsi,
    required this.gambar,
    required this.status,
    required this.tipe,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? '',
      user: json['user'] ?? 'Tidak ada data',
      tanggal: DateTime.parse(json['tanggal']),
      deskripsi: json['deskripsi'] ?? '',
      gambar: json['gambar'] ?? '',
      status: json['status'] ?? '',
      tipe: json['tipe'] ?? '',
    );
  }

  String get formattedTanggal {
    return DateFormat("EEEE, d MMMM yyyy", "id_ID").format(tanggal);
  }

  String get gambarUrl {
    // Return default image if no image is set
    if (gambar.isEmpty) {
      return 'assets/default_event.png';
    }

    // If the image URL is already a full URL, return it as is
    if (gambar.startsWith('http')) {
      return gambar;
    }

    // If it's a relative path, assume it's already correct from the API
    return gambar;
  }
}
