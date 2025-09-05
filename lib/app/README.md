# Aplikasi Radio Odan FM

Folder ini berisi kode inti aplikasi Radio Odan FM.

## Struktur File

- `app.dart` - File utama aplikasi yang berisi `RadioApp` widget dan inisialisasi provider
- `routes/` - Berisi konfigurasi rute aplikasi
- `themes/` - Berisi tema dan gaya aplikasi
- `screens/` - Berisi layar-layar utama aplikasi
- `widgets/` - Berisi komponen UI yang dapat digunakan ulang
- `providers/` - Berisi state management menggunakan Provider
- `services/` - Berisi layanan-layanan yang digunakan aplikasi
- `models/` - Berisi model data aplikasi

## Cara Menambahkan Halaman Baru

1. Buat file baru di folder `screens/` dengan format `nama_halaman_screen.dart`
2. Definisikan rute baru di `app_routes.dart`
3. Tambahkan navigasi menggunakan `context.goNamed()` atau `Navigator.pushNamed()`

## Inisialisasi Aplikasi

Aplikasi diinisialisasi di `main.dart` dengan memanggil `initializeApp()` yang akan:
1. Menginisialisasi Firebase
2. Memuat variabel lingkungan (.env)
3. Menginisialisasi API client
4. Menginisialisasi audio service

## Tema

Aplikasi mendukung tema terang dan gelap yang didefinisikan di `app/themes/`.
