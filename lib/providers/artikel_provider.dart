import 'package:flutter/foundation.dart';
import 'package:radio_odan_app/models/artikel_model.dart';
import 'package:radio_odan_app/services/artikel_service.dart';

class ArtikelProvider with ChangeNotifier {
  final ArtikelService _artikelService = ArtikelService();
  List<Artikel> _artikels = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasMore = true;

  // Getters
  List<Artikel> get artikels => _artikels;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // Fetch initial list of articles
  Future<void> fetchArtikels({bool forceRefresh = false}) async {
    if ((_artikels.isNotEmpty && !forceRefresh) || _isLoading) return;

    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    try {
      final response = await _artikelService.fetchAllArtikel(page: _currentPage);
      _artikels = response['data'];
      _currentPage = response['currentPage'];
      _lastPage = response['lastPage'];
      _hasMore = _currentPage < _lastPage;
      _error = null;
    } catch (e) {
      _error = 'Gagal memuat artikel. Silakan coba lagi.';
      debugPrint('Error fetching artikels: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more articles for pagination
  Future<void> loadMoreArtikels() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _artikelService.fetchAllArtikel(page: nextPage);
      
      _artikels.addAll(response['data']);
      _currentPage = nextPage;
      _lastPage = response['lastPage'];
      _hasMore = _currentPage < _lastPage;
      _error = null;
    } catch (e) {
      _error = 'Gagal memuat artikel tambahan.';
      debugPrint('Error loading more artikels: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Fetch single article by slug
  Future<Artikel?> fetchArtikelBySlug(String slug) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final artikel = await _artikelService.fetchArtikelBySlug(slug);
      _error = null;
      return artikel;
    } catch (e) {
      _error = 'Gagal memuat detail artikel. Silakan coba lagi.';
      debugPrint('Error fetching artikel by slug: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
