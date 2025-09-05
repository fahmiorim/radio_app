# Models

Folder ini berisi model data yang digunakan di seluruh aplikasi Radio Odan FM.

## Daftar Model

- `album_model.dart` - Model untuk data album foto
- `artikel_model.dart` - Model untuk data artikel berita
- `chat_model.dart` - Model untuk data chat/komentar
- `event_model.dart` - Model untuk data event/acara
- `foto_model.dart` - Model untuk data foto
- `kategori_model.dart` - Model untuk kategori konten
- `program_model.dart` - Model untuk program acara radio
- `radio_station_model.dart` - Model untuk stasiun radio
- `user_model.dart` - Model untuk data pengguna
- `video_model.dart` - Model untuk data video

## Konvensi Penamaan

- Nama file menggunakan snake_case dengan akhiran `_model.dart`
- Nama kelas menggunakan PascalCase dengan akhiran `Model`
- Gunakan `@JsonSerializable()` untuk model yang perlu di-serialize dari/dari JSON
- Tambahkan metode `fromJson` dan `toJson` untuk model yang perlu di-serialize

## Contoh Model

```dart
import 'package:json_annotation/json_annotation.dart';

part 'contoh_model.g.dart';

@JsonSerializable()
class ContohModel {
  final int id;
  final String nama;
  final String? deskripsi; // Gunakan ? untuk field opsional
  final DateTime createdAt;

  ContohModel({
    required this.id,
    required this.nama,
    this.deskripsi,
    required this.createdAt,
  });

  factory ContohModel.fromJson(Map<String, dynamic> json) => 
      _$ContohModelFromJson(json);

  Map<String, dynamic> toJson() => _$ContohModelToJson(this);
}
```

## Best Practices

1. **Immutability**
   - Gunakan `final` untuk field yang tidak berubah setelah inisialisasi
   - Buat method `copyWith` untuk membuat salinan dengan beberapa perubahan

2. **Null Safety**
   - Tandai field yang opsional dengan `?`
   - Beri nilai default jika memungkinkan

3. **Dokumentasi**
   - Tambahkan dokumentasi untuk menjelaskan tujuan setiap field
   - Sertakan contoh nilai jika diperlukan

4. **Validasi**
   - Lakukan validasi di konstruktor
   - Gunakan `assert()` untuk memastikan nilai yang valid

5. **Pemisahan**
   - Satu file untuk satu model utama
   - Model terkait bisa diletakkan dalam satu file jika sangat sederhana

## Generate Kode

Untuk model dengan `@JsonSerializable()`, jalankan perintah berikut untuk menghasilkan kode serialisasi:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Penggunaan dengan API

Model-model ini digunakan bersama dengan `ApiClient` untuk mengambil dan menyimpan data dari API. Contoh:

```dart
final response = await ApiClient.I.dio.get('/api/artikel');
final List<ArtikelModel> artikelList = (response.data['data'] as List)
    .map((json) => ArtikelModel.fromJson(json))
    .toList();
```
