import 'package:flutter/foundation.dart';
import '../models/album_model.dart';
import '../services/album_service.dart';

class AlbumProvider with ChangeNotifier {
  final AlbumService _svc = AlbumService.I;

  bool _isLoadingFeatured = false;
  bool _hasErrorFeatured = false;
  String _errorMessageFeatured = '';
  final List<AlbumModel> _featuredAlbums = [];

  bool get isLoadingFeatured => _isLoadingFeatured;
  bool get hasErrorFeatured => _hasErrorFeatured;
  String get errorMessageFeatured => _errorMessageFeatured;
  List<AlbumModel> get featuredAlbums => _featuredAlbums;
  bool get hasFeaturedAlbums => _featuredAlbums.isNotEmpty;

  bool _isLoadingAll = false;
  bool _isLoadingMore = false;
  bool _hasErrorAll = false;
  String _errorMessageAll = '';
  final List<AlbumModel> _allAlbums = [];
  int _currentPage = 1;
  final int _perPage = 10;
  bool _hasMore = true;
  int _totalItems = 0;

  bool get isLoadingAll => _isLoadingAll;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasErrorAll => _hasErrorAll;
  String get errorMessageAll => _errorMessageAll;
  List<AlbumModel> get allAlbums => _allAlbums;
  bool get hasAllAlbums => _allAlbums.isNotEmpty;
  bool get hasMore => _hasMore;
  int get totalItems => _totalItems;

  bool _isLoadingDetail = false;
  String? _detailError;
  AlbumDetailModel? _albumDetail;
  final Map<String, List<PhotoModel>> _albumPhotos =
      {}; // For future photo storage

  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailError => _detailError;
  AlbumDetailModel? get albumDetail => _albumDetail;
  List<PhotoModel>? getAlbumPhotos(String slug) => _albumPhotos[slug];

  Future<void> init() async {
    await Future.wait([fetchFeaturedAlbums(), fetchAllAlbums()]);
  }

  Future<void> fetchFeaturedAlbums({bool forceRefresh = false}) async {
    if (_isLoadingFeatured && !forceRefresh) return;

    _isLoadingFeatured = true;
    _hasErrorFeatured = false;
    _errorMessageFeatured = '';
    notifyListeners();

    try {
      final albums = await _svc.fetchFeaturedAlbums(forceRefresh: forceRefresh);
      _featuredAlbums
        ..clear()
        ..addAll(albums.take(4));
    } catch (e) {
      _hasErrorFeatured = true;
      _errorMessageFeatured = 'Gagal memuat album terbaru. Silakan coba lagi.';
    } finally {
      _isLoadingFeatured = false;
      notifyListeners();
    }
  }

  Future<void> refreshFeaturedAlbums() async {
    // Clear service cache
    await _svc.clearCache();
    // Clear local state
    _featuredAlbums.clear();
    _hasErrorFeatured = false;
    _errorMessageFeatured = '';
    notifyListeners();

    // Force fetch fresh data
    await fetchFeaturedAlbums(forceRefresh: true);
  }

  void clearFeaturedError() {
    _hasErrorFeatured = false;
    _errorMessageFeatured = '';
    notifyListeners();
  }

  Future<void> fetchAllAlbums({bool loadMore = false}) async {
    if ((!loadMore && _isLoadingAll) ||
        (loadMore && (_isLoadingMore || !_hasMore))) {
      return;
    }

    if (!loadMore) {
      _isLoadingAll = true;
      _hasErrorAll = false;
      _errorMessageAll = '';
      _currentPage = 1;
      _hasMore = true;
      _allAlbums.clear();
      notifyListeners();
    } else {
      _isLoadingMore = true;
      notifyListeners();
    }

    try {
      final pageToLoad = loadMore ? (_currentPage + 1) : 1;
      final res = await _svc.fetchAllAlbums(
        page: pageToLoad,
        perPage: _perPage,
      );

      final items = (res['albums'] as List<AlbumModel>);
      final currentPage = (res['currentPage'] as int?) ?? pageToLoad;
      final lastPage = (res['lastPage'] as int?) ?? currentPage;
      _totalItems = (res['total'] as int?) ?? _totalItems;

      if (!loadMore) {
        _allAlbums
          ..clear()
          ..addAll(items);
      } else {
        _allAlbums.addAll(items);
      }

      _hasMore = (currentPage < lastPage) || (items.length == _perPage);
      _currentPage = currentPage;
    } catch (e) {
      _hasErrorAll = true;
      _errorMessageAll = loadMore
          ? 'Gagal memuat album tambahan.'
          : 'Gagal memuat daftar album. Silakan coba lagi.';
    } finally {
      if (loadMore) {
        _isLoadingMore = false;
      } else {
        _isLoadingAll = false;
      }
      notifyListeners();
    }
  }

  Future<void> loadMoreAlbums() => fetchAllAlbums(loadMore: true);

  Future<void> refreshAlbums() async {
    _currentPage = 1;
    _hasMore = true;
    _allAlbums.clear();
    notifyListeners();
    await fetchAllAlbums();
  }

  void resetPagination() {
    _currentPage = 1;
    _hasMore = true;
    _allAlbums.clear();
    notifyListeners();
  }

  void clearListError() {
    _hasErrorAll = false;
    _errorMessageAll = '';
    notifyListeners();
  }

  Future<void> fetchAlbumDetail(String slug) async {
    if (_isLoadingDetail) return;

    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();

    try {
      // First try to find the album in the existing lists
      try {
        // First try to find in featured albums
        final cachedAlbum = _featuredAlbums.firstWhere(
          (album) => album.slug == slug,
        );
        _albumDetail = AlbumDetailModel(
          name: cachedAlbum.name,
          album: cachedAlbum,
          photos: const [],
        );
      } catch (_) {
        try {
          // Then try to find in all albums
          final cachedAlbum = _allAlbums.firstWhere(
            (album) => album.slug == slug,
          );
          _albumDetail = AlbumDetailModel(
            name: cachedAlbum.name,
            album: cachedAlbum,
            photos: const [],
          );
        } catch (_) {
          // If not found in cache, fetch from API
          _albumDetail = await _svc.fetchAlbumDetail(slug);
          // Cache the album details for future use
          if (!_allAlbums.any((a) => a.id == _albumDetail?.album.id)) {
            _allAlbums.add(_albumDetail!.album);
          }
        }
      }
    } catch (e) {
      _detailError = 'Gagal memuat detail album. Silakan coba lagi.';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  void clearDetail() {
    _albumDetail = null;
    _detailError = null;
    notifyListeners();
  }
}
