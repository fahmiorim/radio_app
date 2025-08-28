import 'package:flutter/foundation.dart';
import '../models/album_detail_model.dart';
import '../services/album_service.dart';

class AlbumDetailProvider extends ChangeNotifier {
  final AlbumService _albumService = AlbumService();
  
  AlbumDetailModel? _albumDetail;
  bool _isLoading = false;
  String? _errorMessage;

  AlbumDetailModel? get albumDetail => _albumDetail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> fetchAlbumDetail(String slug) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final albumDetail = await _albumService.fetchAlbumDetail(slug);
      _albumDetail = albumDetail;
    } catch (e) {
      _errorMessage = 'Gagal memuat detail album';
      if (kDebugMode) {
        print('Error fetching album detail: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh(String slug) async {
    await fetchAlbumDetail(slug);
  }
}
