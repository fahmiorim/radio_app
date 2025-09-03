import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../models/program_model.dart';
import '../../../services/program_service.dart';

class ProgramProvider with ChangeNotifier {
  final ProgramService _svc = ProgramService.I;
  

  // ===== Today =====
  List<ProgramModel> _today = [];
  bool _loadingToday = false;
  String? _errorToday;
  DateTime? _lastUpdatedToday;

  // ===== All + Paging =====
  List<ProgramModel> _list = [];
  bool _loadingList = false;
  bool _loadingMore = false;
  String? _errorList;
  int _page = 1;
  int _lastPage = 1;
  bool _hasMore = true;
  DateTime? _lastUpdatedList;

  // ===== Detail =====
  ProgramModel? _selected;
  bool _loadingDetail = false;
  String? _errorDetail;

  // ===== Guards =====
  bool _initialized = false;
  static const Duration _refreshCooldown = Duration(seconds: 45);
  Completer<void>? _inFlightToday;
  Completer<void>? _inFlightList;
  Completer<void>? _inFlightMore;

  // In-flight detail per-ID, agar klik cepat antar item tidak ke-block
  final Map<int, Completer<void>> _detailInFlight = {};

  Timer? _debounce;

  // ===== Getters =====
  List<ProgramModel> get todaysPrograms => _today;
  List<ProgramModel> get allPrograms => _list;
  ProgramModel? get selectedProgram => _selected;

  bool get isLoadingTodays => _loadingToday;
  bool get isLoadingList => _loadingList;
  bool get isLoadingMore => _loadingMore;
  bool get isLoadingDetail => _loadingDetail;
  bool get hasMore => _hasMore;

  String? get todaysError => _errorToday;
  String? get listError => _errorList;
  String? get detailError => _errorDetail;

  // Meta & timestamps (untuk UI)
  int get currentPage => _page;
  int get lastPage => _lastPage;
  DateTime? get lastUpdatedToday => _lastUpdatedToday;
  DateTime? get lastUpdatedList => _lastUpdatedList;

  /// Dipakai di `didChangeAppLifecycleState` (home) untuk auto-refresh
  bool shouldRefreshTodayOnResume([Duration min = _refreshCooldown]) {
    if (_lastUpdatedToday == null) return true;
    return DateTime.now().difference(_lastUpdatedToday!) > min;
  }

  /// Dipakai di halaman list semua program untuk auto-refresh
  bool shouldRefreshListOnResume([Duration min = _refreshCooldown]) {
    if (_lastUpdatedList == null) return true;
    return DateTime.now().difference(_lastUpdatedList!) > min;
  }

  /// Init awal (load today + list) — aman dipanggil berkali-kali
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await Future.wait([
      loadToday(cacheFirst: true),
      loadList(cacheFirst: true),
    ]);
  }

  // ===== Today =====
  Future<void> loadToday({bool cacheFirst = true}) async {
    if (_inFlightToday != null) return _inFlightToday!.future;
    _inFlightToday = Completer<void>();

    _loadingToday = true;
    _errorToday = null;
    notifyListeners();

    try {
      _today = await _svc.fetchToday(forceRefresh: !cacheFirst);
      _errorToday = null;
    } catch (_) {
      _errorToday = 'Gagal memuat program hari ini.';
    } finally {
      _loadingToday = false;
      _lastUpdatedToday = DateTime.now();
      notifyListeners();
      _inFlightToday?.complete();
      _inFlightToday = null;
    }
  }

  Future<void> refreshToday() => loadToday(cacheFirst: false);

  // ===== All + Paging =====
  Future<void> loadList({bool cacheFirst = true}) async {
    if (_inFlightList != null) return _inFlightList!.future;
    _inFlightList = Completer<void>();

    // Cooldown hanya berlaku jika sudah ada data & masih segar
    if (cacheFirst &&
        _list.isNotEmpty &&
        _lastUpdatedList != null &&
        DateTime.now().difference(_lastUpdatedList!) < _refreshCooldown) {
      _inFlightList!.complete();
      _inFlightList = null;
      return;
    }

    _loadingList = true;
    _errorList = null;
    _page = 1;
    _hasMore = true;
    notifyListeners();

    try {
      final res = await _svc.fetchAll(
        page: _page,
        perPage: 10,
        forceRefresh: !cacheFirst,
      );
      _list = (res['data'] as List<ProgramModel>);
      _page = res['currentPage'] as int;
      _lastPage = res['lastPage'] as int;
      _hasMore = _page < _lastPage;
    } catch (_) {
      _errorList = 'Gagal memuat daftar program.';
    } finally {
      _loadingList = false;
      _lastUpdatedList = DateTime.now();
      notifyListeners();
      _inFlightList?.complete();
      _inFlightList = null;
    }
  }

  Future<void> refreshList() => loadList(cacheFirst: false);

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    if (_inFlightMore != null) return _inFlightMore!.future;
    _inFlightMore = Completer<void>();

    _loadingMore = true;
    _errorList = null; // reset error loadMore agar UI bersih
    notifyListeners();

    try {
      final next = _page + 1;
      final res = await _svc.fetchAll(page: next, perPage: 10);
      final newItems = (res['data'] as List<ProgramModel>);
      if (newItems.isNotEmpty) _list.addAll(newItems);
      _page = res['currentPage'] as int;
      _lastPage = res['lastPage'] as int;
      _hasMore = _page < _lastPage;
    } catch (_) {
      _errorList = 'Gagal memuat data tambahan.';
    } finally {
      _loadingMore = false;
      _lastUpdatedList = DateTime.now();
      notifyListeners();
      _inFlightMore?.complete();
      _inFlightMore = null;
    }
  }

  /// Reset state list (untuk hard refresh dari UI jika diperlukan)
  void resetListState() {
    _list = [];
    _page = 1;
    _lastPage = 1;
    _hasMore = true;
    _errorList = null;
    notifyListeners();
  }

  // ===== Detail (per-ID in-flight) =====
  Future<void> fetchDetail(int id, {bool forceRefresh = false}) async {
    final existing = _detailInFlight[id];
    if (existing != null) return existing.future;

    final c = Completer<void>();
    _detailInFlight[id] = c;

    // Update loading state
    _loadingDetail = true;
    _errorDetail = null;
    _selected = null;
    notifyListeners();

    try {
      final response = await _svc.fetchById(id, forceRefresh: forceRefresh);
      _selected = response;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching program detail: $e');
      _errorDetail = 'Gagal memuat detail program.';
      notifyListeners();
    } finally {
      _loadingDetail = false;
      _detailInFlight[id]?.complete();
      _detailInFlight.remove(id);
    }
  }

  void selectProgram(ProgramModel p) {
    _selected = p;
    notifyListeners();
  }

  void clearSelected() {
    _selected = null;
    _errorDetail = null;
    notifyListeners();
  }

  // ===== Debounced refresh (opsional) =====
  Future<void> debouncedRefresh() {
    _debounce?.cancel();
    final c = Completer<void>();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        await Future.wait([
          loadToday(cacheFirst: false),
          loadList(cacheFirst: false),
        ]);
        c.complete();
      } catch (e) {
        c.completeError(e);
      }
    });
    return c.future;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
