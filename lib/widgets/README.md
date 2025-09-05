# Widgets

Folder ini berisi komponen UI yang dapat digunakan ulang di seluruh aplikasi.

## Struktur Folder

- `common/` - Berisi widget yang digunakan di banyak tempat di seluruh aplikasi
  - `app_bar.dart` - AppBar kustom untuk aplikasi
  - `app_drawer.dart` - Drawer navigasi kustom
  - `app_header.dart` - Header untuk halaman
  - `mini_player.dart` - Pemutar audio mini
- `loading/` - Berisi widget untuk indikator loading
  - `loading_widget.dart` - Indikator loading kustom

## Konvensi Penamaan

- Nama file menggunakan snake_case (contoh: `loading_widget.dart`)
- Nama kelas widget menggunakan PascalCase (contoh: `class LoadingWidget`)
- Widget yang digunakan di banyak tempat diletakkan di folder `common/`
- Widget yang spesifik untuk fitur tertentu diletakkan di folder fitur terkait

## Cara Menambahkan Widget Baru

1. Jika widget akan digunakan di banyak tempat, buat di folder `common/`
2. Jika widget spesifik untuk fitur tertentu, buat di folder fitur terkait
3. Pastikan untuk menambahkan dokumentasi di atas deklarasi widget
4. Gunakan `const` constructor jika memungkinkan untuk optimasi performa

## Best Practices

- Buat widget yang kecil dan fokus pada satu tanggung jawab
- Gunakan parameter yang jelas dan beri nilai default jika memungkinkan
- Tambahkan dokumentasi untuk parameter yang kompleks
- Gunakan `const` untuk widget yang statis untuk meningkatkan performa
