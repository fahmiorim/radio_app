import 'package:dio/dio.dart';
import 'dart:developer' as developer;

import 'package:radio_odan_app/models/event_model.dart';
import 'package:radio_odan_app/config/api_client.dart';

class EventService {
  EventService._();
  static final EventService I = EventService._();

  final Dio _dio = ApiClient.I.dio;
  static const String _tag = 'EventService';

  // ==== RECENT EVENTS CACHE ====
  static List<Event>? _recentCache;
  static DateTime? _recentFetchedAt;
  static const Duration _recentTtl = Duration(minutes: 5);

  // ==== PAGINATED EVENTS CACHE ====
  static final Map<String, _PageCache> _pageCache = {};
  static const Duration _pageTtl = Duration(minutes: 10);

  bool _isFresh(DateTime? t, Duration ttl) =>
      t != null && DateTime.now().difference(t) < ttl;

  String _key(int page, int perPage) => 'p:$page|pp:$perPage';

  // ====== FETCH PAGINATED ======
  Future<_PageCache> fetchPaginatedEvents({
    int page = 1,
    int perPage = 10,
    bool forceRefresh = false,
  }) async {
    final key = _key(page, perPage);

    // Jika cache masih fresh dan tidak force refresh → kembalikan dulu
    if (!forceRefresh &&
        _pageCache.containsKey(key) &&
        _isFresh(_pageCache[key]?.fetchedAt, _pageTtl)) {
      developer.log('Using cached events for $key', name: _tag);

      // Background refresh (silent)
      _refreshPageInBackground(page, perPage, key);

      return _pageCache[key]!;
    }

    // Fetch dari server
    return await _fetchPage(page, perPage, key);
  }

  Future<_PageCache> _fetchPage(int page, int perPage, String key) async {
    try {
      developer.log('Fetching paginated events (network) $key', name: _tag);
      final res = await _dio.get(
        '/event/semua',
        queryParameters: {'page': page, 'per_page': perPage},
      );

      if (res.statusCode == 200) {
        final data = res.data;

        if (data is! Map || data['status'] != true || data['data'] is! Map) {
          throw Exception('Format respons tidak valid');
        }

        final responseData = data['data'] as Map<String, dynamic>;
        final list = responseData['data'] is List
            ? (responseData['data'] as List)
            : const [];

        final items = list
            .map((e) => Event.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        final cache = _PageCache(
          items: items,
          currentPage: responseData['current_page'] as int? ?? page,
          lastPage: responseData['last_page'] as int? ?? page,
          total: responseData['total'] as int? ?? items.length,
          hasMore: responseData['next_page_url'] != null,
          fetchedAt: DateTime.now(),
        );

        _pageCache[key] = cache;

        developer.log(
          'Fetched ${items.length} events (page $page of ${cache.lastPage})',
          name: _tag,
        );

        return cache;
      }

      // fallback ke cache kalau ada
      if (_pageCache.containsKey(key)) return _pageCache[key]!;

      throw Exception(
        dataMessage(res.data) ?? 'Gagal mengambil data semua event',
      );
    } on DioException catch (e) {
      developer.log('DioError paginated: ${e.message}', name: _tag, error: e);
      if (_pageCache.containsKey(key)) return _pageCache[key]!;
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      developer.log('Error paginated events', name: _tag, error: e);
      if (_pageCache.containsKey(key)) return _pageCache[key]!;
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<void> _refreshPageInBackground(
    int page,
    int perPage,
    String key,
  ) async {
    try {
      final cache = await _fetchPage(page, perPage, key);
      developer.log(
        'Background refreshed ${cache.items.length} items for $key',
        name: _tag,
      );
    } catch (e) {
      developer.log('Background refresh failed: $e', name: _tag);
    }
  }

  // ====== FETCH RECENT ======
  Future<List<Event>> fetchRecentEvents({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh &&
          _recentCache != null &&
          _isFresh(_recentFetchedAt, _recentTtl)) {
        developer.log('Using cached recent events', name: _tag);

        // background refresh
        _refreshRecentInBackground();

        return _recentCache!;
      }

      return await _fetchRecent();
    } on DioException catch (e) {
      developer.log('DioError recent: ${e.message}', name: _tag, error: e);
      if (_recentCache != null) return _recentCache!;
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      developer.log('Error recent events', name: _tag, error: e);
      if (_recentCache != null) return _recentCache!;
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<List<Event>> _fetchRecent() async {
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

    throw Exception(
      dataMessage(res.data) ?? 'Gagal mengambil data event terbaru',
    );
  }

  Future<void> _refreshRecentInBackground() async {
    try {
      await _fetchRecent();
      developer.log('Background refreshed recent events', name: _tag);
    } catch (e) {
      developer.log('Background refresh failed: $e', name: _tag);
    }
  }

  // ====== UTILS ======
  String? dataMessage(dynamic data) {
    if (data is Map && data['message'] is String)
      return data['message'] as String;
    return null;
  }

  void clearCache() {
    _recentCache = null;
    _recentFetchedAt = null;
    _pageCache.clear();
  }
}

// ====== INTERNAL PAGE CACHE STRUCT ======
class _PageCache {
  final List<Event> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;
  final DateTime fetchedAt;

  _PageCache({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.hasMore,
    required this.fetchedAt,
  });

  Map<String, dynamic> toMap() => {
    'events': items,
    'currentPage': currentPage,
    'lastPage': lastPage,
    'total': total,
    'hasMore': hasMore,
  };
}
