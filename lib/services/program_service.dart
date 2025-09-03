import 'package:dio/dio.dart';
import 'dart:developer' as developer;

import '../config/api_client.dart';
import '../models/program_model.dart';

class ProgramService {
  ProgramService._();
  static final ProgramService I = ProgramService._();

  final Dio _dio = ApiClient.I.dio;

  static const _tag = 'ProgramService';
  static const _basePath = '/program-siaran';

  // TTL
  static const Duration _todayTtl = Duration(minutes: 5);
  static const Duration _allTtl = Duration(minutes: 10);
  static const Duration _detailTtl = Duration(minutes: 5);

  // Cache: today
  static List<ProgramModel>? _todayCache;
  static DateTime? _todayFetchedAt;

  // Cache: all (pagination)
  static final Map<String, List<ProgramModel>> _allCache = {};
  static final Map<String, Map<String, int>> _allMeta = {};
  static final Map<String, DateTime> _allFetchedAt = {};

  // Cache: detail by id
  static final Map<int, ProgramModel> _detailCache = {};
  static final Map<int, DateTime> _detailFetchedAt = {};

  bool _isFresh(DateTime? t, Duration ttl) =>
      t != null && DateTime.now().difference(t) < ttl;

  String _key(int page, int perPage) => 'p:$page|pp:$perPage';

  // ===== Today (/program-siaran)
  Future<List<ProgramModel>> fetchToday({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh &&
          _todayCache != null &&
          _isFresh(_todayFetchedAt, _todayTtl)) {
        developer.log('Using cached today programs', name: _tag);
        _refreshTodayInBackground();
        return _todayCache!;
      }
      return await _fetchTodayNetwork();
    } on DioException catch (e) {
      if (_todayCache != null) return _todayCache!;
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (_todayCache != null) return _todayCache!;
      rethrow;
    }
  }

  Future<List<ProgramModel>> _fetchTodayNetwork() async {
    developer.log('Fetching today programs (network)', name: _tag);
    final res = await _dio.get(_basePath);
    if (res.statusCode == 200) {
      final data = res.data;
      final list = (data is Map && data['data'] is List)
          ? (data['data'] as List)
          : (data is List ? data : const []);
      final items = list
          .map((e) => ProgramModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _todayCache = items;
      _todayFetchedAt = DateTime.now();
      return items;
    }
    throw Exception(_msg(res.data) ?? 'Gagal mengambil program hari ini');
  }

  Future<void> _refreshTodayInBackground() async {
    try {
      await _fetchTodayNetwork();
    } catch (_) {}
  }

  // ===== All (/program-siaran/semua?page=&per_page=)
  Future<Map<String, dynamic>> fetchAll({
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  }) async {
    final key = _key(page, perPage);
    try {
      if (!forceRefresh &&
          _allCache.containsKey(key) &&
          _isFresh(_allFetchedAt[key], _allTtl)) {
        developer.log('Using cached programs for $key', name: _tag);
        _refreshAllInBackground(page, perPage);
        return {'data': _allCache[key]!, ...(_allMeta[key] ?? const {})};
      }
      return await _fetchAllNetwork(page, perPage);
    } on DioException catch (e) {
      if (_allCache.containsKey(key)) {
        return {'data': _allCache[key]!, ...(_allMeta[key] ?? const {})};
      }
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (_allCache.containsKey(key)) {
        return {'data': _allCache[key]!, ...(_allMeta[key] ?? const {})};
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _fetchAllNetwork(int page, int perPage) async {
    final key = _key(page, perPage);
    developer.log('Fetching all programs (network) $key', name: _tag);

    final res = await _dio.get(
      '$_basePath/semua',
      queryParameters: {'page': page, 'per_page': perPage},
    );

    if (res.statusCode == 200) {
      final data = res.data;
      final list = (data is Map && data['data'] is List)
          ? (data['data'] as List)
          : (data is List ? data : const []);
      final items = list
          .map((e) => ProgramModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      int current = page, last = 1, total = items.length, per = perPage;
      if (data is Map && data['pagination'] is Map) {
        final p = data['pagination'] as Map;
        current = _toInt(p['current_page']) ?? current;
        last = _toInt(p['last_page']) ?? last;
        total = _toInt(p['total']) ?? total;
        per = _toInt(p['per_page']) ?? per;
      }

      _allCache[key] = items;
      _allMeta[key] = {
        'currentPage': current,
        'lastPage': last,
        'total': total,
        'perPage': per,
      };
      _allFetchedAt[key] = DateTime.now();

      return {
        'data': items,
        'currentPage': current,
        'lastPage': last,
        'total': total,
        'perPage': per,
      };
    }

    throw Exception(_msg(res.data) ?? 'Gagal mengambil daftar program');
  }

  Future<void> _refreshAllInBackground(int page, int perPage) async {
    try {
      await _fetchAllNetwork(page, perPage);
    } catch (_) {}
  }

  // ===== Detail (/program-siaran/{id})
  Future<ProgramModel> fetchById(int id, {bool forceRefresh = false}) async {
    try {
      if (!forceRefresh &&
          _detailCache.containsKey(id) &&
          _isFresh(_detailFetchedAt[id], _detailTtl)) {
        developer.log('Using cached program id=$id', name: _tag);
        _refreshDetailInBackground(id);
        return _detailCache[id]!;
      }
      return await _fetchDetailNetwork(id);
    } on DioException catch (e) {
      if (_detailCache.containsKey(id)) return _detailCache[id]!;
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      if (_detailCache.containsKey(id)) return _detailCache[id]!;
      rethrow;
    }
  }

  Future<ProgramModel> _fetchDetailNetwork(int id) async {
    developer.log('Fetching program detail id=$id', name: _tag);
    final res = await _dio.get('$_basePath/$id');

    if (res.statusCode == 200) {
      final data = res.data;
      final map = (data is Map && data['data'] is Map)
          ? Map<String, dynamic>.from(data['data'])
          : (data is Map
                ? Map<String, dynamic>.from(data)
                : <String, dynamic>{});

      if (map.isEmpty) throw Exception('Program tidak ditemukan');

      final item = ProgramModel.fromJson(map);
      _detailCache[id] = item;
      _detailFetchedAt[id] = DateTime.now();
      return item;
    }
    if (res.statusCode == 404) throw Exception('Program tidak ditemukan');
    throw Exception(
      _msg(res.data) ??
          'Gagal mengambil detail program (status: ${res.statusCode})',
    );
  }

  Future<void> _refreshDetailInBackground(int id) async {
    try {
      await _fetchDetailNetwork(id);
    } catch (_) {}
  }

  // ===== Utils
  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  String? _msg(dynamic data) {
    if (data is Map && data['message'] is String) return data['message'];
    return null;
  }

  void clearCache() {
    _todayCache = null;
    _todayFetchedAt = null;
    _allCache.clear();
    _allMeta.clear();
    _allFetchedAt.clear();
    _detailCache.clear();
    _detailFetchedAt.clear();
  }
}
