import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:radio_odan_app/models/penyiar_model.dart';
import 'package:radio_odan_app/services/penyiar_service.dart';

class PenyiarProvider with ChangeNotifier {
  final PenyiarService _svc = PenyiarService.I;
  static const Duration _refreshCooldown = Duration(seconds: 30);
  
  List<Penyiar> _items = [];
  bool _isLoading = false;
  DateTime? _lastUpdated;
  String? _error;
  bool _isInitialized = false;
  Timer? _debounceTimer;
  Completer<void>? _currentLoadCompleter;

  List<Penyiar> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _items.isNotEmpty;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await load();
  }

  Future<void> load({bool forceRefresh = false}) async {
    // If a load is already in progress, return its future
    if (_currentLoadCompleter != null) {
      return _currentLoadCompleter!.future;
    }

    // Check cooldown period
    if (!forceRefresh && 
        _lastUpdated != null && 
        DateTime.now().difference(_lastUpdated!) < _refreshCooldown) {
      return;
    }

    _currentLoadCompleter = Completer<void>();
    _isLoading = true;
    _error = null;
    
    // Only notify if we already have data to prevent unnecessary rebuilds
    if (_items.isNotEmpty) notifyListeners();

    try {
      try {
        final data = await _svc.fetchPenyiar(forceRefresh: forceRefresh || _items.isEmpty);
        _items = List<Penyiar>.from(data);
        _error = null;
        _lastUpdated = DateTime.now();
      } catch (e) {
        // Only use cache if we don't have any data
        if (_items.isEmpty) {
          try {
            final cachedData = await _svc.fetchPenyiar(forceRefresh: false);
            if (cachedData.isNotEmpty) {
              _items = List<Penyiar>.from(cachedData);
              _error = 'Mode offline: Menampilkan data terakhir yang tersedia';
            } else {
              throw e;
            }
          } catch (cacheError) {
            _error = 'Gagal memuat data: ${e.toString()}';
            rethrow;
          }
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching penyiar: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      _currentLoadCompleter?.complete();
      _currentLoadCompleter = null;
    }
  }

  Future<void> refresh() {
    // Cancel any pending debounce
    _debounceTimer?.cancel();
    
    // If already refreshing, return the current future
    if (_isLoading) {
      return _currentLoadCompleter?.future ?? Future.value();
    }
    
    // Debounce refresh to prevent multiple rapid calls
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    
    final completer = Completer<void>();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        await load(forceRefresh: true);
        completer.complete();
      } catch (e) {
        completer.completeError(e);
      }
    });
    
    return completer.future;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void clear() {
    _items = [];
    _error = null;
    _lastUpdated = null;
    _svc.clearCache();
    notifyListeners();
  }
}
