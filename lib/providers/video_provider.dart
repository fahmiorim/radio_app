import 'package:flutter/foundation.dart';
import 'package:radio_odan_app/models/video_model.dart';
import 'package:radio_odan_app/services/video_service.dart';

class VideoProvider with ChangeNotifier {
  final VideoService _svc = VideoService.I;

  bool _isLoadingRecent = false;
  bool _hasErrorRecent = false;
  String _errorMessageRecent = '';
  final List<VideoModel> _recentVideos = [];

  bool get isLoadingRecent => _isLoadingRecent;
  bool get hasErrorRecent => _hasErrorRecent;
  String get errorMessageRecent => _errorMessageRecent;
  List<VideoModel> get recentVideos => _recentVideos;
  bool get hasRecentVideos => _recentVideos.isNotEmpty;

  bool _isLoadingAll = false;
  bool _isLoadingMore = false;
  bool _hasErrorAll = false;
  String _errorMessageAll = '';
  final List<VideoModel> _allVideos = [];
  int _currentPage = 1;
  final int _perPage = 10;
  bool _hasMore = true;

  bool get isLoadingAll => _isLoadingAll;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasErrorAll => _hasErrorAll;
  String get errorMessageAll => _errorMessageAll;
  List<VideoModel> get allVideos => _allVideos;
  bool get hasAllVideos => _allVideos.isNotEmpty;
  bool get hasMore => _hasMore;

  Future<void> init() async {
    await Future.wait([fetchRecentVideos(), fetchAllVideos()]);
  }

  Future<void> fetchRecentVideos({bool forceRefresh = false}) async {
    if (_isLoadingRecent) return;

    _isLoadingRecent = true;
    _hasErrorRecent = false;
    _errorMessageRecent = '';
    notifyListeners();

    try {
      final items = await _svc.fetchRecent(forceRefresh: forceRefresh);
      _recentVideos
        ..clear()
        ..addAll(items.take(4));
    } catch (e) {
      _hasErrorRecent = true;
      _errorMessageRecent = 'Gagal memuat video terbaru. Silakan coba lagi.';
      if (kDebugMode) print('Error fetchRecentVideos: $e');
    } finally {
      _isLoadingRecent = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllVideos({bool loadMore = false}) async {
    if (_isLoadingAll ||
        (loadMore && _isLoadingMore) ||
        (!loadMore && _isLoadingMore))
      return;

    if (loadMore) {
      if (!_hasMore) return;
      _isLoadingMore = true;
    } else {
      _isLoadingAll = true;
      _hasErrorAll = false;
      _errorMessageAll = '';
      _currentPage = 1;
      _hasMore = true;
      _allVideos.clear();
    }
    notifyListeners();

    try {
      final res = await _svc.fetchAll(page: _currentPage, perPage: _perPage);
      final items = (res['videos'] as List<VideoModel>);
      final hasMoreRes = (res['hasMore'] as bool?) ?? false;
      final current = (res['currentPage'] as int?) ?? _currentPage;

      _allVideos.addAll(items);
      _hasMore = hasMoreRes;

      if (_hasMore) _currentPage = current + 1;
    } catch (e) {
      _hasErrorAll = true;
      _errorMessageAll = 'Gagal memuat daftar video. Silakan coba lagi.';
      if (kDebugMode) print('Error fetchAllVideos: $e');
    } finally {
      _isLoadingAll = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void clearError({bool recent = true}) {
    if (recent) {
      _hasErrorRecent = false;
      _errorMessageRecent = '';
    } else {
      _hasErrorAll = false;
      _errorMessageAll = '';
    }
    notifyListeners();
  }

  void resetPagination() {
    _currentPage = 1;
    _hasMore = true;
    _allVideos.clear();
    notifyListeners();
  }

  void clearAll() {
    _recentVideos.clear();
    _allVideos.clear();
    _currentPage = 1;
    _hasMore = true;
    _isLoadingRecent = _isLoadingAll = _isLoadingMore = false;
    _hasErrorRecent = _hasErrorAll = false;
    _errorMessageRecent = _errorMessageAll = '';
    notifyListeners();
  }
}
