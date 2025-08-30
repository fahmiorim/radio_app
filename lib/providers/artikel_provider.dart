import 'package:flutter/foundation.dart';
import 'package:radio_odan_app/models/artikel_model.dart';
import 'package:radio_odan_app/services/artikel_service.dart';

class ArtikelProvider with ChangeNotifier {
  final ArtikelService _svc = ArtikelService.I;

  List<Artikel> _recent = [];
  bool _loadingRecent = false;
  String? _errorRecent;

  List<Artikel> _list = [];
  bool _loadingList = false;
  bool _loadingMore = false;
  String? _errorList;
  int _page = 1;
  int _lastPage = 1;
  bool _hasMore = true;

  Artikel? _selected;
  bool _loadingDetail = false;
  String? _errorDetail;

  bool _initialized = false;

  List<Artikel> get recentArtikels => _recent;
  List<Artikel> get artikels => _list;

  Artikel? get selectedArtikel => _selected;

  bool get isLoading => _loadingList;
  bool get isLoadingMore => _loadingMore;
  bool get isLoadingDetail => _loadingDetail;
  bool get hasMore => _hasMore;

  // tambahan kalau butuh loader untuk komponen "recent"
  bool get isLoadingRecent => _loadingRecent;

  // error “utama” (kompatibel), default pakai error list
  String? get error => _errorList;
  String? get recentError => _errorRecent;
  String? get detailError => _errorDetail;

  void clearError() {
    _errorDetail = null;
    _errorList = null;
    _errorRecent = null;
    notifyListeners();
  }

  // ===== Lifecycle =====
  /// panggil sekali di main.dart: ArtikelProvider()..init()
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await Future.wait([
      loadRecent(cacheFirst: true),
      loadList(cacheFirst: true),
    ]);
  }

  Future<void> loadRecent({bool cacheFirst = true}) async {
    if (_loadingRecent) return;
    _loadingRecent = true;
    _errorRecent = null;
    notifyListeners();

    try {
      _recent = await _svc.fetchRecentArtikel(forceRefresh: !cacheFirst);
    } catch (e) {
      _errorRecent = 'Gagal memuat artikel terbaru. Silakan coba lagi.';
    } finally {
      _loadingRecent = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecentArtikels() => loadRecent(cacheFirst: false);
  Future<void> refreshRecent() => loadRecent(cacheFirst: false);

  // ===== List (all + paging) =====
  Future<void> loadList({bool cacheFirst = true}) async {
    if (_loadingList) return;
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
    } catch (e) {
      _errorList = 'Gagal memuat artikel. Silakan coba lagi.';
    } finally {
      _loadingList = false;
      notifyListeners();
    }
  }

  /// KOMPA: tetap sediakan nama lama
  Future<void> fetchArtikels() => loadList(cacheFirst: false);
  Future<void> refresh() => loadList(cacheFirst: false);

  Future<void> loadMoreArtikels() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();

    try {
      final next = _page + 1;
      final res = await _svc.fetchAllArtikel(page: next, perPage: 10);
      final newItems = (res['data'] as List<Artikel>);
      _list.addAll(newItems);
      _page = res['currentPage'] as int;
      _lastPage = res['lastPage'] as int;
      _hasMore = _page < _lastPage;
    } catch (e) {
      _errorList = 'Gagal memuat artikel tambahan. Silakan coba lagi.';
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchArtikelBySlug(String slug) async {
    _loadingDetail = true;
    _errorDetail = null;
    _selected = null;
    notifyListeners();

    try {
      _selected = await _svc.fetchArtikelBySlug(slug);
    } catch (e) {
      _errorDetail = e.toString();
    } finally {
      _loadingDetail = false;
      notifyListeners();
    }
  }

  void clearSelectedArtikel() {
    _selected = null;
    _errorDetail = null;
    notifyListeners();
  }

  void clearErrors() {
    _errorRecent = null;
    _errorList = null;
    _errorDetail = null;
    notifyListeners();
  }
}
