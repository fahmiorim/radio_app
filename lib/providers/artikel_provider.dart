import 'package:flutter/foundation.dart';
import 'package:radio_odan_app/models/artikel_model.dart';
import 'package:radio_odan_app/services/artikel_service.dart';

class ArtikelProvider with ChangeNotifier {
  final ArtikelService _artikelService = ArtikelService();
  List<Artikel> _artikels = [];
  bool _isLoading = true;
  String? _error;

  List<Artikel> get artikels => _artikels;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchArtikels({bool forceRefresh = false}) async {
    // Jika sudah ada data dan bukan force refresh, tidak perlu fetch ulang
    if (_artikels.isNotEmpty && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _artikels = await _artikelService.fetchRecentArtikel();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching artikels: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
