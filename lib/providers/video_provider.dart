import 'package:flutter/foundation.dart';
import 'package:radio_odan_app/models/video_model.dart';
import 'package:radio_odan_app/services/video_service.dart';

class VideoProvider with ChangeNotifier {
  final VideoService _videoService = VideoService();

  // State for recent videos (home screen)
  bool _isLoadingRecent = false;
  bool _hasErrorRecent = false;
  String _errorMessageRecent = '';
  final List<VideoModel> _recentVideos = [];

  // State for all videos (all videos screen)
  bool _isLoadingAll = false;
  bool _hasErrorAll = false;
  String _errorMessageAll = '';
  final List<VideoModel> _allVideos = [];
  int _currentPage = 1;
  bool _hasMore = true;
  final int _perPage = 10;

  // Getters for recent videos
  bool get isLoadingRecent => _isLoadingRecent;
  bool get hasErrorRecent => _hasErrorRecent;
  String get errorMessageRecent => _errorMessageRecent;
  List<VideoModel> get recentVideos => _recentVideos;
  bool get hasRecentVideos => _recentVideos.isNotEmpty;

  // Getters for all videos
  bool get isLoadingAll => _isLoadingAll;
  bool get hasErrorAll => _hasErrorAll;
  String get errorMessageAll => _errorMessageAll;
  List<VideoModel> get allVideos => _allVideos;
  bool get hasAllVideos => _allVideos.isNotEmpty;
  bool get hasMore => _hasMore;

  // Fetch recent videos (for home screen)
  Future<void> fetchRecentVideos() async {
    if (_isLoadingRecent) return;

    try {
      _isLoadingRecent = true;
      _hasErrorRecent = false;
      _errorMessageRecent = '';
      notifyListeners();

      final response = await _videoService.fetchVideos(
        perPage: 4,
      ); // Get 4 most recent videos
      _recentVideos.clear();
      _recentVideos.addAll(response['videos'] as List<VideoModel>);
    } catch (e) {
      _hasErrorRecent = true;
      _errorMessageRecent = 'Gagal memuat video terbaru. Silakan coba lagi.';
      if (kDebugMode) {
        print('Error fetching recent videos: $e');
      }
    } finally {
      _isLoadingRecent = false;
      notifyListeners();
    }
  }

  // Fetch all videos with pagination (for all videos screen)
  Future<void> fetchAllVideos({bool loadMore = false}) async {
    if (_isLoadingAll) return;
    if (!loadMore) _currentPage = 1;

    try {
      _isLoadingAll = true;
      _hasErrorAll = false;
      _errorMessageAll = '';
      if (!loadMore) _allVideos.clear();
      notifyListeners();

      final response = await _videoService.fetchAllVideos(
        page: _currentPage,
        perPage: _perPage,
      );

      final newVideos = response['videos'] as List<VideoModel>;
      final pagination = response['pagination'] as Map<String, dynamic>;

      if (loadMore) {
        _allVideos.addAll(newVideos);
      } else {
        _allVideos.clear();
        _allVideos.addAll(newVideos);
      }

      _hasMore = pagination['current_page'] < pagination['last_page'];
      if (_hasMore) _currentPage++;
    } catch (e) {
      _hasErrorAll = true;
      _errorMessageAll = 'Gagal memuat daftar video. Silakan coba lagi.';
      if (kDebugMode) {
        print('Error fetching all videos: $e');
      }
    } finally {
      _isLoadingAll = false;
      notifyListeners();
    }
  }

  // Clear error states
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

  // Reset pagination and clear all videos
  void resetPagination() {
    _currentPage = 1;
    _hasMore = true;
    _allVideos.clear();
    notifyListeners();
  }
}
