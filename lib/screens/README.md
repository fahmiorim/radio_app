# Screens

Folder ini berisi layar-layar (halaman) utama dari aplikasi Radio Odan FM.

## Struktur Folder

- `artikel/` - Berisi layar terkait artikel berita
  - `artikel_detail_screen.dart` - Halaman detail artikel
  - `artikel_screen.dart` - Daftar artikel
- `event/` - Berisi layar terkait event
  - `all_events_screen.dart` - Daftar semua event
  - `event_detail_screen.dart` - Detail event
- `galeri/` - Berisi layar galeri foto dan video
  - `all_albums_screen.dart` - Daftar album
  - `all_videos_screen.dart` - Daftar video
  - `album_detail_screen.dart` - Detail album foto
  - `galeri_screen.dart` - Halaman utama galeri
- `home/` - Berisi layar beranda
  - `home_screen.dart` - Halaman beranda
- `program/` - Berisi layar program acara
  - `all_programs_screen.dart` - Daftar semua program
  - `program_detail_screen.dart` - Detail program
- `radio/` - Berisi layar pemutar radio
  - `radio_player_screen.dart` - Pemutar radio streaming
- `splash/` - Berisi layar splash
  - `splash_screen.dart` - Layar splash saat aplikasi pertama kali dibuka

## Konvensi Penamaan

- Nama file menggunakan snake_case dengan akhiran `_screen.dart`
- Nama kelas menggunakan PascalCase dengan akhiran `Screen`
- Setiap layar harus merupakan `StatelessWidget` kecuali memerlukan state management
- Gunakan `Consumer` atau `context.watch()` untuk mengakses provider jika diperlukan

## Navigasi

Gunakan `GoRouter` untuk navigasi antar layar. Contoh:

```dart
// Navigasi ke halaman detail
context.goNamed('event-detail', params: {'id': event.id});

// Kembali ke halaman sebelumnya
context.pop();
```

## State Management

Gunakan `Provider` untuk state management. Contoh:

```dart
final eventProvider = Provider.of<EventProvider>(context);
// atau
final eventProvider = context.watch<EventProvider>();
```

## Best Practices

- Pisahkan logika bisnis dari UI dengan menggunakan provider
- Gunakan `const` constructor untuk widget yang statis
- Hindari widget yang terlalu besar, pecah menjadi widget yang lebih kecil
- Gunakan `ListView.builder` untuk daftar yang panjang
- Tambahkan error handling untuk operasi asinkron
