import 'package:flutter/foundation.dart';
import 'package:radio_odan_app/models/artikel_model.dart';
import 'package:radio_odan_app/services/artikel_service.dart';

class ArtikelProvider with ChangeNotifier {
  final ArtikelService _artikelService = ArtikelService();
  List<Artikel> _artikels = [];
  List<Artikel> _recentArtikels = [];
  Artikel? _selectedArtikel;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingDetail = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasMore = true;

  // Getters
  List<Artikel> get artikels => _artikels;
  List<Artikel> get recentArtikels => _recentArtikels;
  Artikel? get selectedArtikel => _selectedArtikel;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Fetch recent articles (for home screen)
  Future<void> fetchRecentArtikels() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recentArtikels = await _artikelService.fetchRecentArtikel();
      _error = null;
    } catch (e) {
      _error = 'Gagal memuat artikel terbaru. Silakan coba lagi.';
      debugPrint('Error fetching recent artikels: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch initial list of articles with pagination
  Future<void> fetchArtikels() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    try {
      final response = await _artikelService.fetchAllArtikel(
        page: _currentPage,
      );
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
    _error = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _artikelService.fetchAllArtikel(page: nextPage);

      _artikels.addAll(response['data']);
      _currentPage = response['currentPage'];
      _lastPage = response['lastPage'];
      _hasMore = _currentPage < _lastPage;
      _error = null;
    } catch (e) {
      _error = 'Gagal memuat artikel tambahan. Silakan coba lagi.';
      debugPrint('Error loading more artikels: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Fetch single article by slug
  Future<void> fetchArtikelBySlug(String slug) async {
    _isLoadingDetail = true;
    _error = null;
    _selectedArtikel = null;
    notifyListeners();

    try {
      _selectedArtikel = await _artikelService.fetchArtikelBySlug(slug);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching artikel detail: $e');
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  // Clear selected article
  void clearSelectedArtikel() {
    _selectedArtikel = null;
    notifyListeners();
  }
}
