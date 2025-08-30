import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/penyiar_model.dart';
import '../config/api_client.dart';

class PenyiarService {
  PenyiarService._();
  static final PenyiarService I = PenyiarService._();

  final Dio _dio = ApiClient.I.dio;

  static List<Penyiar>? _cache;

  Future<List<Penyiar>> fetchPenyiar({bool forceRefresh = false}) async {
    // Selalu ambil data baru dari server
    if (!forceRefresh && _cache != null) {
      // Kembalikan data cache sambil tetap fetch data terbaru di background
      _fetchInBackground();
      return _cache!;
    }

    try {
      final res = await _dio.get('/penyiar');

      if (res.statusCode == 200) {
        final data = res.data;

        final list = (data is Map && data['data'] is List)
            ? (data['data'] as List)
            : (data as List);

        final items = list
            .map((e) => Penyiar.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        _cache = items;

        return items;
      }

      if (_cache != null) return _cache!;
      throw Exception(
        'Gagal mengambil data penyiar. Status: ${res.statusCode}',
      );
    } on DioException catch (e) {
      if (_cache != null) return _cache!;
      throw Exception('Error jaringan: ${e.message}');
    } catch (e) {
      if (_cache != null) return _cache!;
      rethrow;
    }
  }

  Future<void> _fetchInBackground() async {
    try {
      final res = await _dio.get('/penyiar');
      if (res.statusCode == 200) {
        final data = res.data;
        final list = (data is Map && data['data'] is List)
            ? (data['data'] as List)
            : (data as List);

        _cache = list
            .map((e) => Penyiar.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      // Ignore error in background fetch
      debugPrint('Background fetch error: $e');
    }
  }

  void clearCache() {
    _cache = null;
  }
}
