import 'package:dio/dio.dart';
import '../models/video_model.dart';
import '../config/api_client.dart';

class VideoService {
  VideoService._();
  static final VideoService I = VideoService._();

  final Dio _dio = ApiClient.I.dio;

  static List<VideoModel>? _cacheRecent;
  static DateTime? _cacheAt;
  static const Duration _ttl = Duration(minutes: 5);

  // Clear cached data
  Future<void> clearCache() async {
    _cacheRecent = null;
    _cacheAt = null;
  }

  Future<List<VideoModel>> fetchRecent({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final isFresh = _cacheAt != null && now.difference(_cacheAt!) < _ttl;
    if (!forceRefresh && _cacheRecent != null && isFresh) return _cacheRecent!;

    try {
      final res = await _dio.get('/video');

      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data['status'] == true && data['data'] is List) {
          final list = data['data'] as List;
          final items = list
              .whereType<Map>()
              .map((e) => VideoModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          _cacheRecent = items;
          _cacheAt = now;
          return items;
        }
        throw Exception('Format respons tidak valid');
      }

      if (_cacheRecent != null) return _cacheRecent!;
      throw Exception('Gagal mengambil video. Status: ${res.statusCode}');
    } on DioException catch (e) {
      if (_cacheRecent != null) return _cacheRecent!;
      throw Exception('Error jaringan: ${e.message}');
    } catch (e) {
      if (_cacheRecent != null) return _cacheRecent!;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchAll({
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  }) async {
    try {
      final res = await _dio.get(
        '/video/semua',
        queryParameters: {'page': page, 'per_page': perPage},
      );

      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data['status'] == true) {
          // Handle pagination data
          int currentPage = page;
          int lastPage = 1;
          int total = 0;

          // Extract videos
          final list = (data['data'] is List)
              ? (data['data'] as List)
              : const [];

          final items = list
              .whereType<Map>()
              .map((e) => VideoModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          // Extract pagination info if available
          if (data['pagination'] is Map) {
            final pagination = data['pagination'] as Map;
            currentPage = int.tryParse('${pagination['current_page']}') ?? page;
            lastPage = int.tryParse('${pagination['last_page']}') ?? 1;
            total = int.tryParse('${pagination['total']}') ?? items.length;
            perPage = int.tryParse('${pagination['per_page']}') ?? perPage;
          } else {
            // Fallback if no pagination data
            currentPage = page;
            lastPage = items.length >= perPage ? page + 1 : page;
            total = items.length;
          }

          return {
            'videos': items,
            'currentPage': currentPage,
            'lastPage': lastPage,
            'total': total,
            'perPage': perPage,
            'hasMore': currentPage < lastPage,
          };
        }
        throw Exception('Format respons tidak valid');
      }

      throw Exception(
        'Gagal mengambil daftar video. Status: ${res.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception('Error jaringan: ${e.message}');
    }
  }

  Future<VideoModel> fetchDetail(int id) async {
    try {
      final res = await _dio.get('/video/$id');

      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data['data'] != null) {
          return VideoModel.fromJson(Map<String, dynamic>.from(data['data']));
        }
      }
      throw Exception('Gagal memuat detail video');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Video tidak ditemukan');
      }
      throw Exception('Error jaringan: ${e.message}');
    }
  }
}
