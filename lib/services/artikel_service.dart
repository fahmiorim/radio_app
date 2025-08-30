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

  static List<Artikel>? _recentCache;
  static DateTime? _recentFetchedAt;
  static const Duration _recentTtl = Duration(minutes: 5);

  static final Map<String, List<Artikel>> _allCache = {};
  static final Map<String, Map<String, int>> _allMeta = {};
  static final Map<String, DateTime> _allFetchedAt = {};
  static const Duration _allTtl = Duration(minutes: 10);

  bool _isFresh(DateTime? t, Duration ttl) =>
      t != null && DateTime.now().difference(t) < ttl;
  String _key(int page, int perPage) => 'p:$page|pp:$perPage';

  Future<List<Artikel>> fetchRecentArtikel({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh &&
          _recentCache != null &&
          _isFresh(_recentFetchedAt, _recentTtl)) {
        developer.log('Using cached recent news', name: _tag);
        return _recentCache!;
      }

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

      if (_recentCache != null) return _recentCache!;
      throw Exception(
        _messageOf(res.data) ?? 'Gagal mengambil data artikel terbaru',
      );
    } on DioException catch (e) {
      if (_recentCache != null) return _recentCache!;
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (_recentCache != null) return _recentCache!;
      rethrow;
    }
  }

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
        final meta = _allMeta[key] ?? const {'currentPage': 1, 'lastPage': 1};
        return {
          'data': _allCache[key]!,
          'currentPage': meta['currentPage']!,
          'lastPage': meta['lastPage']!,
        };
      }

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
          // Handle pagination from 'pagination' object
          if (data['pagination'] is Map) {
            final pagination = data['pagination'] as Map;
            currentPage = _intOf(pagination['current_page'] ?? pagination['currentPage']) ?? page;
            lastPage = _intOf(pagination['last_page'] ?? pagination['lastPage']) ?? 1;
            totalItems = _intOf(pagination['total']) ?? 0;
          } 
          // Fallback to direct fields
          else {
            currentPage = _intOf(_pick(data, ['current_page', 'currentPage'])) ?? page;
            lastPage = _intOf(_pick(data, ['last_page', 'lastPage'])) ?? 1;
            totalItems = _intOf(data['total'] ?? 0) ?? 0;
          }
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

      if (_allCache.containsKey(key)) {
        final meta = _allMeta[key] ?? const {'currentPage': 1, 'lastPage': 1};
        return {
          'data': _allCache[key]!,
          'currentPage': meta['currentPage']!,
          'lastPage': meta['lastPage']!,
        };
      }
      throw Exception(_messageOf(res.data) ?? 'Gagal mengambil data artikel');
    } on DioException catch (e) {
      if (_allCache.containsKey(key)) {
        final meta = _allMeta[key] ?? const {'currentPage': 1, 'lastPage': 1};
        return {
          'data': _allCache[key]!,
          'currentPage': meta['currentPage']!,
          'lastPage': meta['lastPage']!,
        };
      }
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (_allCache.containsKey(key)) {
        final meta = _allMeta[key] ?? const {'currentPage': 1, 'lastPage': 1};
        return {
          'data': _allCache[key]!,
          'currentPage': meta['currentPage']!,
          'lastPage': meta['lastPage']!,
        };
      }
      rethrow;
    }
  }

  Future<Artikel> fetchArtikelBySlug(String slug) async {
    try {
      developer.log('Fetching article by slug: $slug', name: _tag);
      final res = await _dio.get('$_basePath/$slug');

      if (res.statusCode == 200) {
        final data = res.data;
        final map =
            (data is Map && data['status'] == true && data['data'] is Map)
            ? Map<String, dynamic>.from(data['data'])
            : (data is Map
                  ? Map<String, dynamic>.from(data)
                  : <String, dynamic>{});
        if (map.isEmpty) throw Exception('Artikel tidak ada');
        return Artikel.fromJson(map);
      }
      if (res.statusCode == 404) throw Exception('Artikel tidak ada');
      throw Exception(
        _messageOf(res.data) ??
            'Gagal mengambil detail artikel. Kode status: ${res.statusCode}',
      );
    } on DioException catch (e) {
      final resp = e.response;
      if (resp?.statusCode == 404) {
        throw Exception('Artikel tidak ada');
      }
      if (resp?.data != null) {
        throw Exception(
          _messageOf(resp!.data) ?? 'Gagal mengambil detail artikel',
        );
      }
      throw Exception('Tidak dapat terhubung ke server: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  void clearCache() {
    _recentCache = null;
    _recentFetchedAt = null;
    _allCache.clear();
    _allMeta.clear();
    _allFetchedAt.clear();
  }

  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      // Handle direct data array in response
      if (data['data'] is List) return data['data'] as List;
      
      // Handle status-based response
      if (data['status'] == true && data['data'] is List) {
        return data['data'] as List;
      }
      
      // Handle nested data structure
      if (data['data'] is Map) {
        final inner = data['data'] as Map;
        if (inner['data'] is List) return inner['data'] as List;
      }
      
      // Handle root-level array with pagination
      if (data['pagination'] is Map) {
        final list = <dynamic>[];
        // Copy all non-pagination fields that are lists
        data.forEach((key, value) {
          if (key != 'pagination' && key != 'status' && value is List) {
            list.addAll(value);
          }
        });
        return list;
      }
    }
    return const [];
  }

  String? _messageOf(dynamic data) {
    if (data is Map && data['message'] is String)
      return data['message'] as String;
    return null;
  }

  int? _intOf(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  dynamic _pick(Map obj, List<String> keys) {
    for (final k in keys) {
      if (obj[k] != null) return obj[k];
    }
    return null;
  }
}
