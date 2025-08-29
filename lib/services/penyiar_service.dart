// lib/services/penyiar_service.dart
import 'package:dio/dio.dart';
import '../models/penyiar_model.dart';
import '../config/api_client.dart';

class PenyiarService {
  PenyiarService._();
  static final PenyiarService I = PenyiarService._();

  final Dio _dio = ApiClient.I.dio;

  static List<Penyiar>? _cache;
  static DateTime? _fetchedAt;
  static const Duration _ttl = Duration(minutes: 5);

  Future<List<Penyiar>> fetchPenyiar({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final isFresh = _fetchedAt != null && now.difference(_fetchedAt!) < _ttl;
    if (!forceRefresh && _cache != null && isFresh) {
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
        _fetchedAt = now;

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

  void clearCache() {
    _cache = null;
    _fetchedAt = null;
  }
}
