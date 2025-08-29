import 'package:dio/dio.dart';
import 'dart:developer' as developer;

import '../models/event_model.dart';
import '../config/api_client.dart';

class EventService {
  EventService._();
  static final EventService I = EventService._();

  final Dio _dio = ApiClient.I.dio;
  static const String _tag = 'EventService';

  static List<Event>? _recentCache;
  static DateTime? _recentFetchedAt;
  static const Duration _recentTtl = Duration(minutes: 5);

  static final Map<String, List<Event>> _allCache = {};
  static final Map<String, DateTime> _allFetchedAt = {};
  static const Duration _allTtl = Duration(minutes: 10);

  bool _isFresh(DateTime? t, Duration ttl) =>
      t != null && DateTime.now().difference(t) < ttl;

  String _key(int page, int perPage) => 'p:$page|pp:$perPage';

  Future<List<Event>> fetchAllEvents({
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  }) async {
    final key = _key(page, perPage);

    try {
      if (!forceRefresh &&
          _allCache.containsKey(key) &&
          _isFresh(_allFetchedAt[key], _allTtl)) {
        developer.log('Using cached events for $key', name: _tag);
        return _allCache[key]!;
      }

      developer.log('Fetching all events (network) $key', name: _tag);
      final res = await _dio.get(
        '/event/semua',
        queryParameters: {'page': page, 'per_page': perPage},
      );

      if (res.statusCode == 200) {
        final data = res.data;

        final list =
            (data is Map && data['status'] == true && data['data'] is List)
            ? (data['data'] as List)
            : (data is List ? data : const []);

        final items = list
            .map((e) => Event.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        _allCache[key] = items;
        _allFetchedAt[key] = DateTime.now();
        developer.log('Fetched ${items.length} events for $key', name: _tag);

        return items;
      }

      if (_allCache.containsKey(key)) return _allCache[key]!;
      throw Exception(
        res.data is Map && res.data['message'] != null
            ? res.data['message']
            : 'Gagal mengambil data semua event',
      );
    } on DioException catch (e) {
      developer.log('DioError all events: ${e.message}', name: _tag, error: e);
      if (_allCache.containsKey(key)) return _allCache[key]!;
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      developer.log('Error all events', name: _tag, error: e);
      if (_allCache.containsKey(key)) return _allCache[key]!;
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<List<Event>> fetchRecentEvents({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh &&
          _recentCache != null &&
          _isFresh(_recentFetchedAt, _recentTtl)) {
        developer.log('Using cached recent events', name: _tag);
        return _recentCache!;
      }

      developer.log('Fetching recent events (network)', name: _tag);
      final res = await _dio.get('/event');

      if (res.statusCode == 200) {
        final data = res.data;
        final list =
            (data is Map && data['status'] == true && data['data'] is List)
            ? (data['data'] as List)
            : (data is List ? data : const []);

        final items = list
            .map((e) => Event.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        _recentCache = items;
        _recentFetchedAt = DateTime.now();
        developer.log('Fetched ${items.length} recent events', name: _tag);

        return items;
      }

      if (_recentCache != null) return _recentCache!;
      throw Exception(
        dataMessage(res.data) ?? 'Gagal mengambil data event terbaru',
      );
    } on DioException catch (e) {
      developer.log(
        'DioError recent events: ${e.message}',
        name: _tag,
        error: e,
      );
      if (_recentCache != null) return _recentCache!;
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      developer.log('Error recent events', name: _tag, error: e);
      if (_recentCache != null) return _recentCache!;
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  String? dataMessage(dynamic data) {
    if (data is Map && data['message'] is String)
      return data['message'] as String;
    return null;
  }

  void clearCache() {
    _recentCache = null;
    _recentFetchedAt = null;
    _allCache.clear();
    _allFetchedAt.clear();
  }
}
