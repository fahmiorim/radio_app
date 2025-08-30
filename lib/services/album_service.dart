import 'package:dio/dio.dart';
import '../config/api_client.dart';
import '../config/app_api_config.dart';
import '../models/album_model.dart';

class AlbumService {
  AlbumService._();
  static final AlbumService I = AlbumService._();

  // Clear all caches
  Future<void> clearCache() async {
    _featuredCache = null;
    _featuredAt = null;
    _allCache.clear();
    _allAt = null;
    _detailCache.clear();
    _detailAt.clear();
  }

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
    } on DioError catch (e) {
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
        'hasMore': false,
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

        if (data is Map && data['status'] == true) {
          // Process album list
          final List<dynamic> items = data['data'] is List ? data['data'] : [];
          final List<AlbumModel> albums = [];

          for (var item in items) {
            try {
              if (item is Map) {
                final albumData = Map<String, dynamic>.from(item);
                // Ensure we have a proper cover image URL
                if (albumData['cover_image'] == null &&
                    albumData['image'] != null) {
                  albumData['cover_image'] = albumData['image'];
                }
                // Ensure cover image has full URL
                if (albumData['cover_image'] is String &&
                    !albumData['cover_image'].toString().startsWith('http')) {
                  albumData['cover_image'] =
                      '${AppApiConfig.assetBaseUrl}${albumData['cover_image']}';
                }
                albums.add(AlbumModel.fromJson(albumData));
              }
            } catch (e) {
              print('Error processing album item: $e');
              // Skip this item and continue with the next one
              continue;
            }
          }

          _allCache[page] = albums;
          _allAt = DateTime.now();

          final pagination = data['pagination'] ?? {};
          final currentPage = _asInt(pagination['current_page'] ?? page);
          final lastPage = _asInt(pagination['last_page'] ?? page);
          final total = _asInt(pagination['total'] ?? albums.length);

          _allCache[page] = albums;
          _allAt = DateTime.now();

          return {
            'albums': albums,
            'currentPage': currentPage,
            'lastPage': lastPage,
            'total': total,
            'hasMore': currentPage < lastPage,
          };
        }
      }

      if (_allCache[page] != null) {
        final items = _allCache[page]!;
        return {
          'albums': items,
          'currentPage': page,
          'lastPage': page,
          'total': items.length,
          'hasMore': false,
        };
      }
      throw Exception('Gagal memuat daftar album (status ${res.statusCode})');
    } on DioError catch (e) {
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

  Future<AlbumDetailModel> fetchAlbumDetail(
    String slug, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'detail-$slug';
    if (!forceRefresh &&
        _detailCache[cacheKey] != null &&
        _isFresh(_detailAt[cacheKey])) {
      return _detailCache[cacheKey]!;
    }

    try {
      final res = await _dio.get('/galeri/$slug');
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data['status'] == true && data['data'] is Map) {
          final responseData = Map<String, dynamic>.from(data['data']);

          // Handle the case where photos is a string ("Tidak ada foto")
          if (responseData['photos'] is String) {
            responseData['photos'] = [];
          }

          final albumDetail = AlbumDetailModel.fromJson(responseData);
          _detailCache[cacheKey] = albumDetail;
          _detailAt[cacheKey] = DateTime.now();

          return albumDetail;
        }
        throw Exception(
          (data is Map ? data['message'] : null) ??
              'Format respons tidak valid',
        );
      }
      throw Exception('Gagal memuat detail album (status ${res.statusCode})');
    } on DioError catch (e) {
      // Return cached data if available
      if (_detailCache[cacheKey] != null) {
        return _detailCache[cacheKey]!;
      }

      throw Exception('Gagal memuat detail album: ${e.message}');
    } catch (e) {
      // Return cached data if available
      if (_detailCache[cacheKey] != null) {
        return _detailCache[cacheKey]!;
      }
      rethrow;
    }
  }
}
