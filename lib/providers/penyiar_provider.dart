import 'package:flutter/foundation.dart';
import 'package:radio_odan_app/models/penyiar_model.dart';
import 'package:radio_odan_app/services/penyiar_service.dart';

class PenyiarProvider with ChangeNotifier {
  final PenyiarService _penyiarService = PenyiarService();
  List<Penyiar> _penyiars = [];
  bool _isLoading = true;
  String? _error;

  List<Penyiar> get penyiars => _penyiars;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPenyiars({bool forceRefresh = false}) async {
    // Jika sudah ada data dan bukan force refresh, tidak perlu fetch ulang
    if (_penyiars.isNotEmpty && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _penyiars = await _penyiarService.fetchPenyiar();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching penyiars: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
