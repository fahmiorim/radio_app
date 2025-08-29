// lib/services/program_service.dart
import 'package:dio/dio.dart';
import 'dart:developer' as developer;

import '../models/program_model.dart';
import '../config/api_client.dart';

class ProgramService {
  ProgramService._();
  static final ProgramService I = ProgramService._();

  final Dio _dio = ApiClient.I.dio;
  static const String _tag = 'ProgramService';

  static List<Program>? _todayCache;
  static DateTime? _todayFetchedAt;
  static const Duration _todayTtl = Duration(minutes: 5);

  static List<Program>? _allCache;
  static DateTime? _allFetchedAt;
  static const Duration _allTtl = Duration(minutes: 10);

  static final Map<int, Program> _detailCache = {};
  static final Map<int, DateTime> _detailFetchedAt = {};
  static const Duration _detailTtl = Duration(minutes: 30);

  bool _isFresh(DateTime? t, Duration ttl) =>
      t != null && DateTime.now().difference(t) < ttl;

  Future<List<Program>> fetchTodaysPrograms({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh &&
          _todayCache != null &&
          _isFresh(_todayFetchedAt, _todayTtl)) {
        developer.log('Using cached today programs', name: _tag);
        return _todayCache!;
      }

      developer.log('Fetching today\'s programs (network)', name: _tag);
      final res = await _dio.get('/program-siaran');

      if (res.statusCode == 200) {
        final data = res.data;
        final list =
            (data is Map && data['status'] == true && data['data'] is List)
            ? (data['data'] as List)
            : (data is List ? data : const []);

        final items = list
            .map((e) => Program.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        _todayCache = items;
        _todayFetchedAt = DateTime.now();
        developer.log('Fetched ${items.length} today programs', name: _tag);
        return items;
      }

      if (_todayCache != null) return _todayCache!;
      throw Exception(
        res.data is Map && res.data['message'] != null
            ? res.data['message']
            : 'Gagal mengambil data program siaran hari ini',
      );
    } on DioException catch (e) {
      developer.log(
        'DioError today programs: ${e.message}',
        name: _tag,
        error: e,
      );
      if (_todayCache != null) return _todayCache!;
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      developer.log('Error today programs', name: _tag, error: e);
      if (_todayCache != null) return _todayCache!;
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<Map<String, dynamic>> fetchAllPrograms({
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh &&
          _allCache != null &&
          _isFresh(_allFetchedAt, _allTtl)) {
        developer.log('Using cached all programs', name: _tag);
        return {
          'programs': _allCache!,
          'currentPage': 1,
          'lastPage': 1,
          'total': _allCache!.length,
          'hasMore': false,
        };
      }

      developer.log('Fetching all programs (network)', name: _tag);
      final res = await _dio.get('/program-siaran/semua');

      if (res.statusCode == 200) {
        final data = res.data;
        final list =
            (data is Map && data['status'] == true && data['data'] is List)
            ? (data['data'] as List)
            : (data is List ? data : const []);

        final items = list
            .map((e) => Program.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        _allCache = items;
        _allFetchedAt = DateTime.now();
        developer.log('Fetched ${items.length} programs', name: _tag);

        return {
          'programs': items,
          'currentPage': 1,
          'lastPage': 1,
          'total': items.length,
          'hasMore': false,
        };
      }

      if (_allCache != null) {
        return {
          'programs': _allCache!,
          'currentPage': 1,
          'lastPage': 1,
          'total': _allCache!.length,
          'hasMore': false,
        };
      }
      throw Exception(
        res.data is Map && res.data['message'] != null
            ? res.data['message']
            : 'Gagal mengambil daftar program',
      );
    } on DioException catch (e) {
      developer.log(
        'DioError all programs: ${e.message}',
        name: _tag,
        error: e,
      );
      if (_allCache != null) {
        return {
          'programs': _allCache!,
          'currentPage': 1,
          'lastPage': 1,
          'total': _allCache!.length,
          'hasMore': false,
        };
      }
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      developer.log('Error all programs', name: _tag, error: e);
      if (_allCache != null) {
        return {
          'programs': _allCache!,
          'currentPage': 1,
          'lastPage': 1,
          'total': _allCache!.length,
          'hasMore': false,
        };
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<Program> fetchProgramById(int id, {bool forceRefresh = false}) async {
    try {
      final at = _detailFetchedAt[id];
      if (!forceRefresh &&
          _detailCache.containsKey(id) &&
          _isFresh(at, _detailTtl)) {
        developer.log('Using cached program #$id', name: _tag);
        return _detailCache[id]!;
      }

      developer.log(
        'Fetching program details for ID: $id (network)',
        name: _tag,
      );
      final res = await _dio.get('/program-siaran/$id');

      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map && data['status'] == true && data['data'] != null) {
          final program = Program.fromJson(
            Map<String, dynamic>.from(data['data']),
          );
          _detailCache[id] = program;
          _detailFetchedAt[id] = DateTime.now();
          return program;
        }
      }

      if (_detailCache.containsKey(id)) return _detailCache[id]!;
      if (res.statusCode == 404) throw Exception('Program tidak ditemukan');
      throw Exception(
        res.data is Map && res.data['message'] != null
            ? res.data['message']
            : 'Gagal mengambil detail program',
      );
    } on DioException catch (e) {
      developer.log('DioError program $id: ${e.message}', name: _tag, error: e);
      if (_detailCache.containsKey(id)) return _detailCache[id]!;
      if (e.response?.statusCode == 404)
        throw Exception('Program tidak ditemukan');
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      developer.log('Error program $id', name: _tag, error: e);
      if (_detailCache.containsKey(id)) return _detailCache[id]!;
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  void clearCache() {
    _todayCache = null;
    _todayFetchedAt = null;
    _allCache = null;
    _allFetchedAt = null;
    _detailCache.clear();
    _detailFetchedAt.clear();
  }
}
