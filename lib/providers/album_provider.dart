import 'package:flutter/foundation.dart';
import 'package:radio_odan_app/models/album_model.dart';
import 'package:radio_odan_app/services/album_service.dart';

class AlbumProvider with ChangeNotifier {
  final AlbumService _albumService = AlbumService();

  // State for featured albums (home screen)
  bool _isLoadingFeatured = false;
  bool _hasErrorFeatured = false;
  String _errorMessageFeatured = '';
  final List<AlbumModel> _featuredAlbums = [];

  // State for all albums (all albums screen)
  bool _isLoadingAll = false;
  bool _hasErrorAll = false;
  String _errorMessageAll = '';
  final List<AlbumModel> _allAlbums = [];
  int _currentPage = 1;
  bool _hasMore = true;
  final int _perPage = 10;
  int _totalItems = 0;

  // Getters for featured albums
  bool get isLoadingFeatured => _isLoadingFeatured;
  bool get hasErrorFeatured => _hasErrorFeatured;
  String get errorMessageFeatured => _errorMessageFeatured;
  List<AlbumModel> get featuredAlbums => _featuredAlbums;
  bool get hasFeaturedAlbums => _featuredAlbums.isNotEmpty;

  // Getters for all albums
  bool get isLoadingAll => _isLoadingAll;
  bool get hasErrorAll => _hasErrorAll;
  String get errorMessageAll => _errorMessageAll;
  int get totalItems => _totalItems;
  List<AlbumModel> get allAlbums => _allAlbums;
  bool get hasAllAlbums => _allAlbums.isNotEmpty;
  bool get hasMore => _hasMore;

  // Fetch featured albums (for home screen - 4 albums)
  Future<void> fetchFeaturedAlbums() async {
    if (_isLoadingFeatured) return;

    try {
      _isLoadingFeatured = true;
      _hasErrorFeatured = false;
      _errorMessageFeatured = '';
      notifyListeners();

      final albums = await _albumService.fetchFeaturedAlbums();
      _featuredAlbums.clear();
      _featuredAlbums.addAll(albums.take(4)); // Only take 4 albums for featured
    } catch (e) {
      _hasErrorFeatured = true;
      _errorMessageFeatured = 'Gagal memuat album terbaru. Silakan coba lagi.';
      if (kDebugMode) {
        print('Error fetching featured albums: $e');
      }
    } finally {
      _isLoadingFeatured = false;
      notifyListeners();
    }
  }

  // Fetch all albums with pagination (for all albums screen)
  Future<void> fetchAllAlbums({bool loadMore = false}) async {
    if (_isLoadingAll) return;
    if (!loadMore) _currentPage = 1;

    try {
      _isLoadingAll = true;
      _hasErrorAll = false;
      _errorMessageAll = '';
      if (!loadMore) _allAlbums.clear();
      notifyListeners();

      final response = await _albumService.fetchAllAlbums(
        page: _currentPage,
        perPage: _perPage,
      );

      final List<AlbumModel> albums = [];
      if (response.containsKey('albums') && response['albums'] is List) {
        albums.addAll((response['albums'] as List).cast<AlbumModel>());
        _currentPage = response['currentPage'] ?? _currentPage;
        _totalItems = response['total'] ?? 0;
      }

      if (loadMore) {
        _allAlbums.addAll(albums);
      } else {
        _allAlbums.clear();
        _allAlbums.addAll(albums);
      }

      _hasMore =
          albums.length >=
          _perPage; // If we got a full page, there might be more
      if (_hasMore) _currentPage++;
    } catch (e) {
      _hasErrorAll = true;
      _errorMessageAll = 'Gagal memuat daftar album. Silakan coba lagi.';
      if (kDebugMode) {
        print('Error fetching all albums: $e');
      }
    } finally {
      _isLoadingAll = false;
      notifyListeners();
    }
  }

  // Clear error states
  void clearError({bool featured = true}) {
    if (featured) {
      _hasErrorFeatured = false;
      _errorMessageFeatured = '';
    } else {
      _hasErrorAll = false;
      _errorMessageAll = '';
    }
    notifyListeners();
  }

  // Reset pagination and clear all albums
  void resetPagination() {
    _currentPage = 1;
    _hasMore = true;
    _allAlbums.clear();
    notifyListeners();
  }
  // Add these methods to the AlbumProvider class

  Future<void> loadMoreAlbums() async {
    if (_isLoadingAll || !_hasMore) return;

    _isLoadingAll = true;
    _currentPage++;
    notifyListeners();

    try {
      final response = await _albumService.fetchAllAlbums(page: _currentPage);
      _allAlbums.addAll(response['data']);
      _hasMore = response['next_page_url'] != null;
      _isLoadingAll = false;
      notifyListeners();
    } catch (e) {
      _isLoadingAll = false;
      _errorMessageAll = 'Gagal memuat album tambahan';
      notifyListeners();
    }
  }

  Future<void> refreshAlbums() async {
    _currentPage = 1;
    _hasMore = true;
    _allAlbums.clear();
    notifyListeners();

    return fetchAllAlbums();
  }
}
