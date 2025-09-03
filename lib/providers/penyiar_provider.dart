import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:radio_odan_app/models/penyiar_model.dart';
import 'package:radio_odan_app/services/penyiar_service.dart';

class PenyiarProvider with ChangeNotifier {
  final PenyiarService _svc = PenyiarService.I;

  // Minimal interval agar tidak spam API saat resume/berpindah layar
  static const Duration _refreshCooldown = Duration(seconds: 30);

  List<Penyiar> _items = [];
  bool _isLoading = false;
  String? _error;

  DateTime? _lastUpdated;
  bool _initialized = false;

  // Guard agar tidak ada load ganda
  Completer<void>? _inFlight;
  // Debounce refresh (mis. pull-to-refresh bertubi-tubi)
  Timer? _debounce;

  // Getters
  List<Penyiar> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _items.isNotEmpty;

  /// Dipanggil sekali saat pertama kali widget yang memakai provider ini muncul
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await load(cacheFirst: true);
  }

  /// Load data.
  /// - cacheFirst=true : tampilkan cache dulu (jika ada), service nanti revalidate di background.
  /// - cacheFirst=false/force : paksa ambil terbaru.
  Future<void> load({bool cacheFirst = true}) async {
    // Jika masih ada request berjalan, ikuti saja
    if (_inFlight != null) return _inFlight!.future;

    // Hargai cooldown (kecuali saat pertama init atau ketika cacheFirst=false)
    if (cacheFirst &&
        _lastUpdated != null &&
        DateTime.now().difference(_lastUpdated!) < _refreshCooldown) {
      return;
    }

    _inFlight = Completer<void>();
    _isLoading = true;
    _error = null;
    // Beritahu UI selalu saat mulai loading agar skeleton bisa tampil
    notifyListeners();

    try {
      // Serahkan logika cache/fallback ke service
      final data = await _svc.fetchPenyiar(
        cacheFirst: cacheFirst,
        forceRefresh: !cacheFirst || _items.isEmpty,
      );

      _items = List<Penyiar>.from(data);
      _lastUpdated = DateTime.now();
      _error = null;
    } catch (e) {
      // Kalau service sudah fallback ke cache tapi tetap error, tampilkan pesan
      _error = e.toString();
    } finally {
      _isLoading = false;
      _inFlight?.complete();
      _inFlight = null;
      notifyListeners();
    }
  }

  /// Paksa refresh (abaikan cache). Sudah didebounce.
  Future<void> refresh() {
    _debounce?.cancel();
    final c = Completer<void>();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        await load(cacheFirst: false); // force ke jaringan
        c.complete();
      } catch (e) {
        c.completeError(e);
      }
    });
    return c.future;
  }

  /// Dipakai oleh widget saat onResume untuk throttle refresh otomatis
  bool shouldRefreshOnResume([
    Duration minInterval = const Duration(seconds: 45),
  ]) {
    if (_lastUpdated == null) return true;
    return DateTime.now().difference(_lastUpdated!) > minInterval;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Bersihkan semua state & cache service (mis. saat logout)
  void clear() {
    _items = [];
    _error = null;
    _lastUpdated = null;
    _svc.clearCache();
    notifyListeners();
  }
}
