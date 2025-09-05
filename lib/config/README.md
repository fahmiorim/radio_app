# Konfigurasi Aplikasi

Folder ini berisi file-file konfigurasi untuk aplikasi Radio Odan FM.

## Daftar File Konfigurasi

- `api_client.dart` - Konfigurasi HTTP client untuk berkomunikasi dengan API
- `app_api_config.dart` - Konfigurasi URL dan endpoint API
- `app_colors.dart` - Warna-warna yang digunakan di aplikasi
- `app_theme.dart` - Tema aplikasi (light/dark mode)
- `constants.dart` - Konstanta yang digunakan di seluruh aplikasi
- `routes.dart` - Konfigurasi rute aplikasi
- `theme_config.dart` - Konfigurasi tema tambahan

## Penggunaan

### API Client

`ApiClient` adalah singleton yang menangani semua permintaan HTTP ke server. Contoh penggunaan:

```dart
// Mendapatkan instance ApiClient
final apiClient = ApiClient.I;

// Melakukan GET request
final response = await apiClient.dio.get('/api/endpoint');

// Melakukan POST request dengan data
final postResponse = await apiClient.dio.post(
  '/api/endpoint',
  data: {'key': 'value'},
);
```

### Tema Aplikasi

Aplikasi mendukung tema terang dan gelap. Untuk menggunakan tema:

```dart
// Mengakses tema saat ini
theme: Theme.of(context),

// Mengakses warna kustom
color: AppColors.primary,

// Menggunakan teks style
textTheme: AppTheme.textTheme,
```

### Rute Aplikasi

Untuk navigasi, gunakan `GoRouter` yang sudah dikonfigurasi di `routes.dart`:

```dart
// Navigasi ke halaman
context.goNamed('route-name');

// Navigasi dengan parameter
context.goNamed('detail', params: {'id': '123'});

// Kembali ke halaman sebelumnya
context.pop();
```

## Konfigurasi Lingkungan

Aplikasi menggunakan `dotenv` untuk mengelola variabel lingkungan. File `.env` harus berisi:

```
API_BASE_URL=https://api.odanfm.com
# Tambahkan variabel lingkungan lain yang diperlukan
```

## Best Practices

1. **API Client**
   - Gunakan `ApiClient.I` untuk mengakses instance API client
   - Tangani error dengan try-catch
   - Gunakan model yang sesuai untuk request/response

2. **Tema**
   - Gunakan warna dari `AppColors` untuk konsistensi
   - Gunakan `AppTheme` untuk style yang konsisten
   - Sesuaikan tema di `AppTheme` jika diperlukan

3. **Rute**
   - Gunakan named routes yang didefinisikan di `routes.dart`
   - Hindari hardcode string route di seluruh aplikasi
   - Gunakan parameter route untuk mengirim data antar halaman

4. **Konstanta**
   - Simpan nilai konstan di `constants.dart`
   - Gunakan konstanta daripada nilai hardcode
   - Kelompokkan konstanta yang terkait

## Penyesuaian

1. **Mengubah Tema**
   - Sesuaikan warna di `app_colors.dart`
   - Sesuaikan tema di `app_theme.dart`
   - Restart aplikasi untuk melihat perubahan

2. **Mengubah API Base URL**
   - Update `API_BASE_URL` di file `.env`
   - Atau ubah di `app_api_config.dart` untuk development

3. **Menambahkan Rute Baru**
   - Tambahkan rute baru di `routes.dart`
   - Buat screen yang sesuai di folder `screens/`
   - Update navigasi di tempat yang sesuai
