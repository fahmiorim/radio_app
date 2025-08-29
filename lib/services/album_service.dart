import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/album_model.dart';
import '../config/api_client.dart';

class AlbumService {
  AlbumService._();
  static final AlbumService I = AlbumService._();

  final Dio _dio = ApiClient.I.dio;

  static const Duration _ttl = Duration(minutes: 5);

  static List<AlbumModel>? _featuredCache;
  static DateTime? _featuredAt;

  static final Map<int, List<AlbumModel>> _allCache = {};
  static DateTime? _allAt;

  static final Map<String, AlbumDetailModel> _detailCache = {};
  static final Map<String, DateTime> _detailAt = {};

  bool _isFresh(DateTime? at) =>
      at != null && DateTime.now().difference(at) < _ttl;

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  Future<List<AlbumModel>> fetchFeaturedAlbums({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _featuredCache != null && _isFresh(_featuredAt)) {
      return _featuredCache!;
    }

    try {
      final res = await _dio.get('/galeri');
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data['status'] == true && data['data'] is List) {
          final list = (data['data'] as List)
              .whereType<Map>()
              .map((e) => AlbumModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          _featuredCache = list;
          _featuredAt = DateTime.now();
          return list;
        }
      }

      if (_featuredCache != null) return _featuredCache!;
      throw Exception(
        'Gagal memuat featured albums (status ${res.statusCode})',
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('AlbumService.fetchFeaturedAlbums DioError: ${e.message}');
      }
      if (_featuredCache != null) return _featuredCache!;
      throw Exception('Gagal memuat album: ${e.message}');
    } catch (e) {
      if (_featuredCache != null) return _featuredCache!;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchAllAlbums({
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _allCache[page] != null && _isFresh(_allAt)) {
      final items = _allCache[page]!;
      return {
        'albums': items,
        'currentPage': page,
        'lastPage': page,
        'total': items.length,
      };
    }

    try {
      final res = await _dio.get(
        '/galeri/semua',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'with_photos': 'true',
        },
      );

      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data['status'] == true && data['data'] is List) {
          final items = (data['data'] as List)
              .whereType<Map>()
              .map((e) => AlbumModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          final pg = (data['pagination'] is Map)
              ? Map<String, dynamic>.from(data['pagination'])
              : const <String, dynamic>{};

          final currentPage = _asInt(pg['current_page'], fallback: page);
          final lastPage = _asInt(pg['last_page'], fallback: currentPage);
          final total = _asInt(pg['total'], fallback: items.length);

          _allCache[currentPage] = items;
          _allAt = DateTime.now();

          return {
            'albums': items,
            'currentPage': currentPage,
            'lastPage': lastPage,
            'total': total,
          };
        }
      }

      if (_allCache[page] != null) {
        return {
          'albums': _allCache[page]!,
          'currentPage': page,
          'lastPage': page,
          'total': _allCache[page]!.length,
        };
      }
      throw Exception('Gagal memuat daftar album (status ${res.statusCode})');
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('AlbumService.fetchAllAlbums DioError: ${e.message}');
      }
      if (_allCache[page] != null) {
        return {
          'albums': _allCache[page]!,
          'currentPage': page,
          'lastPage': page,
          'total': _allCache[page]!.length,
        };
      }
      throw Exception('Gagal memuat daftar album: ${e.message}');
    } catch (e) {
      if (_allCache[page] != null) {
        return {
          'albums': _allCache[page]!,
          'currentPage': page,
          'lastPage': page,
          'total': _allCache[page]!.length,
        };
      }
      rethrow;
    }
  }

  Future<AlbumModel> fetchAlbumDetail(
    String slug, {
    bool forceRefresh = false,
  }) async {
    try {
      final res = await _dio.get('/galeri/$slug');
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data['status'] == true && data['data'] != null) {
          return AlbumModel.fromJson(
            Map<String, dynamic>.from(data['data']),
          );
        }
        throw Exception(
          (data is Map ? data['message'] : null) ?? 'Data album tidak valid',
        );
      }
      throw Exception('Gagal memuat detail album (status ${res.statusCode})');
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('AlbumService.fetchAlbumDetail DioError: ${e.message}');
      }
      throw Exception('Gagal memuat detail album: ${e.message}');
    }
  }

  void clearCache() {
    _featuredCache = null;
    _featuredAt = null;
    _allCache.clear();
    _allAt = null;
    _detailCache.clear();
    _detailAt.clear();
  }
}
