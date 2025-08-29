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

  Future<List<VideoModel>> fetchRecent({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final isFresh = _cacheAt != null && now.difference(_cacheAt!) < _ttl;
    if (!forceRefresh && _cacheRecent != null && isFresh) return _cacheRecent!;

    try {
      final res = await _dio.get('/video');

      if (res.statusCode == 200) {
        final data = res.data;
        final list = (data is Map && data['data'] is List)
            ? (data['data'] as List)
            : (data as List? ?? const []);

        final items = list
            .map((e) => VideoModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        _cacheRecent = items;
        _cacheAt = now;
        return items;
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
  }) async {
    try {
      final res = await _dio.get(
        '/video/semua',
        queryParameters: {'page': page, 'per_page': perPage},
      );

      if (res.statusCode == 200) {
        final data = res.data;

        final list = (data is Map && data['data'] is List)
            ? (data['data'] as List)
            : const <dynamic>[];

        final items = list
            .map((e) => VideoModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        int currentPage = page;
        int lastPage = page;
        int total = items.length;
        bool hasMore;

        if (data is Map && data['pagination'] is Map) {
          final p = Map<String, dynamic>.from(data['pagination']);
          currentPage =
              int.tryParse(
                '${p['current_page'] ?? p['currentPage'] ?? page}',
              ) ??
              page;
          lastPage =
              int.tryParse('${p['last_page'] ?? p['lastPage'] ?? page}') ??
              page;
          total = int.tryParse('${p['total'] ?? items.length}') ?? items.length;
        } else {
          currentPage = page;
          lastPage = items.length == perPage ? page + 1 : page;
        }

        hasMore = currentPage < lastPage;

        return {
          'videos': items,
          'currentPage': currentPage,
          'lastPage': lastPage,
          'total': total,
          'hasMore': hasMore,
        };
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

  void clearCache() {
    _cacheRecent = null;
    _cacheAt = null;
  }
}
