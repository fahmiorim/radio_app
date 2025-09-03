import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:radio_odan_app/models/artikel_model.dart';
import 'package:radio_odan_app/services/artikel_service.dart';

class ArtikelProvider with ChangeNotifier {
  final ArtikelService _svc = ArtikelService.I;

  // ===== State: Recent =====
  List<Artikel> _recent = [];
  bool _loadingRecent = false;
  String? _errorRecent;

  // ===== State: List (paging) =====
  List<Artikel> _list = [];
  bool _loadingList = false;
  bool _loadingMore = false;
  String? _errorList;
  int _page = 1;
  int _lastPage = 1;
  bool _hasMore = true;

  // ===== State: Detail =====
  Artikel? _selected;
  bool _loadingDetail = false;
  String? _errorDetail;

  // ===== Lifecycle/guards =====
  bool _initialized = false;
  DateTime? _lastUpdated; // untuk throttle refresh on resume
  static const Duration _refreshCooldown = Duration(seconds: 45);

  Completer<void>? _inFlightRecent;
  Completer<void>? _inFlightList;
  Completer<void>? _inFlightMore;
  Completer<void>? _inFlightDetail;

  Timer? _debounce; // debounce untuk refresh manual

  // ===== Getters =====
  List<Artikel> get recentArtikels => _recent;
  List<Artikel> get artikels => _list;
  Artikel? get selectedArtikel => _selected;

  bool get isLoading => _loadingList;
  bool get isLoadingMore => _loadingMore;
  bool get isLoadingDetail => _loadingDetail;
  bool get isLoadingRecent => _loadingRecent;
  bool get hasMore => _hasMore;

  // error “utama” (kompatibel dgn UI lama)
  String? get error => _errorList;
  String? get recentError => _errorRecent;
  String? get detailError => _errorDetail;

  // ===== Helpers =====
  void clearError() {
    _errorDetail = null;
    _errorList = null;
    _errorRecent = null;
    notifyListeners();
  }

  void clearErrors() => clearError();

  bool shouldRefreshOnResume([Duration minInterval = _refreshCooldown]) {
    if (_lastUpdated == null) return true;
    return DateTime.now().difference(_lastUpdated!) > minInterval;
  }

  // ===== Lifecycle =====
  /// panggil sekali saat app start atau saat provider diregistrasi
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await Future.wait([
      loadRecent(cacheFirst: true),
      loadList(cacheFirst: true),
    ]);
  }

  // ===== Recent =====
  Future<void> loadRecent({bool cacheFirst = true}) async {
    // in-flight guard
    if (_inFlightRecent != null) return _inFlightRecent!.future;
    _inFlightRecent = Completer<void>();

    _loadingRecent = true;
    _errorRecent = null;
    notifyListeners();

    try {
      _recent = await _svc.fetchRecentArtikel(forceRefresh: !cacheFirst);
    } catch (e) {
      _errorRecent = 'Gagal memuat artikel terbaru. Silakan coba lagi.';
    } finally {
      _loadingRecent = false;
      _lastUpdated = DateTime.now();
      notifyListeners();
      _inFlightRecent?.complete();
      _inFlightRecent = null;
    }
  }

  Future<void> fetchRecentArtikels() => loadRecent(cacheFirst: false);
  Future<void> refreshRecent() => loadRecent(cacheFirst: false);

  // ===== List (all + paging) =====
  Future<void> loadList({bool cacheFirst = true}) async {
    // in-flight guard
    if (_inFlightList != null) return _inFlightList!.future;
    _inFlightList = Completer<void>();

    // cooldown untuk menghindari spam (diabaikan kalau cacheFirst=false / force)
    if (cacheFirst &&
        _lastUpdated != null &&
        DateTime.now().difference(_lastUpdated!) < _refreshCooldown) {
      _inFlightList!.complete();
      _inFlightList = null;
      return;
    }

    _loadingList = true;
    _errorList = null;
    _page = 1;
    _hasMore = true;
    notifyListeners();

    try {
      final res = await _svc.fetchAllArtikel(
        page: _page,
        perPage: 10,
        forceRefresh: !cacheFirst,
      );
      _list = (res['data'] as List<Artikel>);
      _page = res['currentPage'] as int;
      _lastPage = res['lastPage'] as int;
      _hasMore = _page < _lastPage;
      _errorList = null;
    } catch (e) {
      _errorList = 'Gagal memuat artikel. Silakan coba lagi.';
    } finally {
      _loadingList = false;
      _lastUpdated = DateTime.now();
      notifyListeners();
      _inFlightList?.complete();
      _inFlightList = null;
    }
  }

  /// Alias kompatibel
  Future<void> fetchArtikels() => loadList(cacheFirst: false);
  Future<void> refresh() => loadList(cacheFirst: false);

  Future<void> loadMoreArtikels() async {
    if (_loadingMore || !_hasMore) return;
    // in-flight guard
    if (_inFlightMore != null) return _inFlightMore!.future;
    _inFlightMore = Completer<void>();

    _loadingMore = true;
    notifyListeners();

    try {
      final next = _page + 1;
      final res = await _svc.fetchAllArtikel(page: next, perPage: 10);
      final newItems = (res['data'] as List<Artikel>);
      if (newItems.isNotEmpty) {
        _list.addAll(newItems);
      }
      _page = res['currentPage'] as int;
      _lastPage = res['lastPage'] as int;
      _hasMore = _page < _lastPage;
      _errorList = null;
    } catch (e) {
      _errorList = 'Gagal memuat artikel tambahan. Silakan coba lagi.';
    } finally {
      _loadingMore = false;
      _lastUpdated = DateTime.now();
      notifyListeners();
      _inFlightMore?.complete();
      _inFlightMore = null;
    }
  }

  // ===== Detail =====
  Future<void> fetchArtikelBySlug(
    String slug, {
    bool forceRefresh = false,
  }) async {
    // in-flight guard
    if (_inFlightDetail != null) return _inFlightDetail!.future;
    _inFlightDetail = Completer<void>();

    _loadingDetail = true;
    _errorDetail = null;
    _selected = null;
    notifyListeners();

    try {
      _selected = await _svc.fetchArtikelBySlug(
        slug,
        forceRefresh: forceRefresh,
      );
      _errorDetail = null;
    } catch (e) {
      _errorDetail = e.toString();
    } finally {
      _loadingDetail = false;
      notifyListeners();
      _inFlightDetail?.complete();
      _inFlightDetail = null;
    }
  }

  void clearSelectedArtikel() {
    _selected = null;
    _errorDetail = null;
    notifyListeners();
  }

  // ===== Manual debounce refresh (mis. dari UI pull-to-refresh) =====
  Future<void> debouncedRefresh() {
    _debounce?.cancel();
    final c = Completer<void>();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        await loadRecent(cacheFirst: false);
        await loadList(cacheFirst: false);
        c.complete();
      } catch (e) {
        c.completeError(e);
      }
    });
    return c.future;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
