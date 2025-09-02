import 'package:dio/dio.dart';
import 'dart:developer' as developer;

import '../models/penyiar_model.dart';
import '../config/api_client.dart';

class PenyiarService {
  PenyiarService._();
  static final PenyiarService I = PenyiarService._();

  final Dio _dio = ApiClient.I.dio;
  static const _tag = 'PenyiarService';

  // ===== Cache + TTL =====
  static List<Penyiar>? _cache;
  static DateTime? _fetchedAt;
  // samakan gaya dengan recent events (boleh diubah 5–10 menit sesuai kebutuhan)
  static const Duration _ttl = Duration(minutes: 5);

  bool _isFresh(DateTime? t, Duration ttl) =>
      t != null && DateTime.now().difference(t) < ttl;

  /// Ambil daftar penyiar.
  /// - `cacheFirst = true`: tampilkan cache dulu (kalau ada & fresh), lalu refresh di background.
  /// - `forceRefresh = true`: abaikan cache, langsung tembak jaringan.
  Future<List<Penyiar>> fetchPenyiar({
    bool cacheFirst = true,
    bool forceRefresh = false,
  }) async {
    // Pakai cache kalau masih fresh & tidak dipaksa refresh
    if (!forceRefresh && _cache != null && _isFresh(_fetchedAt, _ttl)) {
      developer.log('Using cached penyiar (fresh)', name: _tag);

      // Revalidate di background agar sinkron kalau server berubah
      if (cacheFirst) _refreshInBackground();
      return _cache!;
    }

    // Jika cache ada tapi expired, tetap kembalikan cache dulu kalau cacheFirst,
    // sambil langsung refresh jaringan (UX lebih cepat).
    if (!forceRefresh && cacheFirst && _cache != null) {
      developer.log(
        'Using cached penyiar (stale) + background refresh',
        name: _tag,
      );
      _refreshInBackground(); // tidak await
      return _cache!;
    }

    // Otherwise, fetch jaringan
    return await _fetch();
  }

  Future<List<Penyiar>> _fetch() async {
    try {
      developer.log('Fetching penyiar (network)', name: _tag);
      final res = await _dio.get('/penyiar');

      if (res.statusCode == 200) {
        final data = res.data;

        final list = (data is Map && data['data'] is List)
            ? (data['data'] as List)
            : (data is List ? data : const []);

        final items = list
            .map((e) => Penyiar.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        _cache = items;
        _fetchedAt = DateTime.now();

        developer.log('Fetched ${items.length} penyiar', name: _tag);
        return items;
      }

      // Gagal tapi ada cache → fallback
      if (_cache != null) {
        developer.log('Fetch failed, fallback to cache', name: _tag);
        return _cache!;
      }

      throw Exception(_dataMessage(res.data) ?? 'Gagal mengambil data penyiar');
    } on DioException catch (e) {
      developer.log('DioError penyiar: ${e.message}', name: _tag, error: e);
      if (_cache != null) return _cache!;
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      developer.log('Error penyiar', name: _tag, error: e);
      if (_cache != null) return _cache!;
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      await _fetch();
      developer.log('Background refreshed penyiar', name: _tag);
    } catch (e) {
      developer.log('Background refresh failed: $e', name: _tag);
    }
  }

  String? _dataMessage(dynamic data) {
    if (data is Map && data['message'] is String)
      return data['message'] as String;
    return null;
  }

  void clearCache() {
    _cache = null;
    _fetchedAt = null;
  }
}
