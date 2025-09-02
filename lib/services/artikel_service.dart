import 'package:dio/dio.dart';
import 'dart:developer' as developer;

import '../models/artikel_model.dart';
import '../config/api_client.dart';

class ArtikelService {
  ArtikelService._();
  static final ArtikelService I = ArtikelService._();

  final Dio _dio = ApiClient.I.dio;
  static const String _basePath = '/news';
  static const String _tag = 'ArtikelService';

  // TTL
  static const Duration _recentTtl = Duration(minutes: 5);
  static const Duration _allTtl = Duration(minutes: 10);
  static const Duration _detailTtl = Duration(minutes: 5);

  // Recent cache
  static List<Artikel>? _recentCache;
  static DateTime? _recentFetchedAt;

  // All cache (pagination)
  static final Map<String, List<Artikel>> _allCache = {};
  static final Map<String, Map<String, int>> _allMeta = {};
  static final Map<String, DateTime> _allFetchedAt = {};

  // Detail cache
  static final Map<String, Artikel> _detailCache = {};
  static final Map<String, DateTime> _detailFetchedAt = {};

  // Utils
  bool _isFresh(DateTime? t, Duration ttl) =>
      t != null && DateTime.now().difference(t) < ttl;

  String _key(int page, int perPage) => 'p:$page|pp:$perPage';

  // 🔹 Recent news
  Future<List<Artikel>> fetchRecentArtikel({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh &&
          _recentCache != null &&
          _isFresh(_recentFetchedAt, _recentTtl)) {
        developer.log('Using cached recent news', name: _tag);
        // background refresh
        _fetchRecentInBackground();
        return _recentCache!;
      }

      return await _fetchRecentNetwork();
    } on DioException catch (e) {
      if (_recentCache != null) return _recentCache!;
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (_recentCache != null) return _recentCache!;
      rethrow;
    }
  }

  Future<List<Artikel>> _fetchRecentNetwork() async {
    developer.log('Fetching recent news (network)', name: _tag);
    final res = await _dio.get(_basePath);

    if (res.statusCode == 200) {
      final list = _extractList(res.data);
      final items = list
          .map<Artikel>((e) => Artikel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      _recentCache = items;
      _recentFetchedAt = DateTime.now();
      return items;
    }

    throw Exception(_messageOf(res.data) ?? 'Gagal mengambil berita terbaru');
  }

  Future<void> _fetchRecentInBackground() async {
    try {
      await _fetchRecentNetwork();
    } catch (_) {
      // silent fail
    }
  }

  // 🔹 All news (paginated)
  Future<Map<String, dynamic>> fetchAllArtikel({
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  }) async {
    final key = _key(page, perPage);

    try {
      if (!forceRefresh &&
          _allCache.containsKey(key) &&
          _isFresh(_allFetchedAt[key], _allTtl)) {
        developer.log('Using cached news for $key', name: _tag);
        _fetchAllInBackground(page, perPage);
        return {'data': _allCache[key]!, ..._allMeta[key]!};
      }

      return await _fetchAllNetwork(page, perPage);
    } on DioException catch (e) {
      if (_allCache.containsKey(key)) {
        return {'data': _allCache[key]!, ..._allMeta[key]!};
      }
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (_allCache.containsKey(key)) {
        return {'data': _allCache[key]!, ..._allMeta[key]!};
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _fetchAllNetwork(int page, int perPage) async {
    final key = _key(page, perPage);
    developer.log('Fetching all news (network) $key', name: _tag);

    final res = await _dio.get(
      '$_basePath/semua',
      queryParameters: {'page': page, 'per_page': perPage},
    );

    if (res.statusCode == 200) {
      final data = res.data;
      final list = _extractList(data);
      final items = list
          .map<Artikel>((e) => Artikel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      int currentPage = page;
      int lastPage = 1;
      int totalItems = 0;

      if (data is Map) {
        final pagination = (data['pagination'] ?? data) as Map;
        currentPage =
            _intOf(pagination['current_page'] ?? pagination['currentPage']) ??
            page;
        lastPage =
            _intOf(pagination['last_page'] ?? pagination['lastPage']) ?? 1;
        totalItems = _intOf(pagination['total']) ?? items.length;
      }

      _allCache[key] = items;
      _allMeta[key] = {
        'currentPage': currentPage,
        'lastPage': lastPage,
        'total': totalItems,
        'perPage': perPage,
      };
      _allFetchedAt[key] = DateTime.now();

      return {
        'data': items,
        'currentPage': currentPage,
        'lastPage': lastPage,
        'total': totalItems,
        'perPage': perPage,
      };
    }

    throw Exception(_messageOf(res.data) ?? 'Gagal mengambil artikel');
  }

  Future<void> _fetchAllInBackground(int page, int perPage) async {
    try {
      await _fetchAllNetwork(page, perPage);
    } catch (_) {}
  }

  // 🔹 Detail by slug
  Future<Artikel> fetchArtikelBySlug(
    String slug, {
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh &&
          _detailCache.containsKey(slug) &&
          _isFresh(_detailFetchedAt[slug], _detailTtl)) {
        developer.log('Using cached article slug=$slug', name: _tag);
        _fetchDetailInBackground(slug);
        return _detailCache[slug]!;
      }

      return await _fetchDetailNetwork(slug);
    } on DioException catch (e) {
      if (_detailCache.containsKey(slug)) return _detailCache[slug]!;
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (_detailCache.containsKey(slug)) return _detailCache[slug]!;
      rethrow;
    }
  }

  Future<Artikel> _fetchDetailNetwork(String slug) async {
    developer.log('Fetching article by slug: $slug', name: _tag);
    final res = await _dio.get('$_basePath/$slug');

    if (res.statusCode == 200) {
      final data = res.data;
      final map = (data is Map && data['data'] is Map)
          ? Map<String, dynamic>.from(data['data'])
          : Map<String, dynamic>.from(data as Map);
      final artikel = Artikel.fromJson(map);

      _detailCache[slug] = artikel;
      _detailFetchedAt[slug] = DateTime.now();

      return artikel;
    }
    if (res.statusCode == 404) throw Exception('Artikel tidak ada');
    throw Exception(
      _messageOf(res.data) ??
          'Gagal mengambil detail artikel (status: ${res.statusCode})',
    );
  }

  Future<void> _fetchDetailInBackground(String slug) async {
    try {
      await _fetchDetailNetwork(slug);
    } catch (_) {}
  }

  // 🔹 Utils
  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data['data'] is List) return data['data'] as List;
      if (data['status'] == true && data['data'] is List) {
        return data['data'] as List;
      }
      if (data['data'] is Map && (data['data'] as Map)['data'] is List) {
        return (data['data'] as Map)['data'] as List;
      }
    }
    return const [];
  }

  String? _messageOf(dynamic data) {
    if (data is Map && data['message'] is String) return data['message'];
    return null;
  }

  int? _intOf(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  void clearCache() {
    _recentCache = null;
    _recentFetchedAt = null;
    _allCache.clear();
    _allMeta.clear();
    _allFetchedAt.clear();
    _detailCache.clear();
    _detailFetchedAt.clear();
  }
}
