import 'package:flutter/foundation.dart';
import 'package:radio_odan_app/models/penyiar_model.dart';
import 'package:radio_odan_app/services/penyiar_service.dart';

class PenyiarProvider with ChangeNotifier {
  final PenyiarService _svc = PenyiarService.I;

  List<Penyiar> _items = [];
  bool _isLoading = false;
  String? _error;
  bool _initialized = false; // ⬅️ tambahan

  List<Penyiar> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _items.isNotEmpty;

  Future<void> init() async {
    if (_initialized) return; // ⬅️ cegah init ganda
    _initialized = true;
    await load(cacheFirst: true);
  }

  Future<void> load({bool cacheFirst = true}) async {
    if (_isLoading) return; // dedupe
    _isLoading = true;
    _error = null;
    notifyListeners(); // tampilkan loading di UI

    try {
      final data = await _svc.fetchPenyiar(forceRefresh: !cacheFirst);
      _items = data;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching penyiar: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // selesai loading (sukses/gagal)
    }
  }

  Future<void> refresh() => load(cacheFirst: false);

  void clear() {
    _items = [];
    _error = null;
    _svc.clearCache();
    notifyListeners();
  }
}
