import 'package:flutter/material.dart';
import 'package:radio_odan_app/models/event_model.dart';
import 'package:radio_odan_app/services/event_service.dart';

class EventProvider with ChangeNotifier {
  final EventService _svc = EventService.I;

  List<Event> _events = [];
  Event? _selectedEvent;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _initialized = false;

  List<Event> get events => _events;
  Event? get selectedEvent => _selectedEvent;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await load(cacheFirst: true);
  }

  /// Initial load → pakai recent events
  Future<void> load({bool cacheFirst = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final recentEvents = await _svc.fetchRecentEvents(
        forceRefresh: !cacheFirst,
      );

      _events = recentEvents;
      _currentPage = 1;
      _lastPage = 1;
      _hasMore = recentEvents.length >= 10;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await load(cacheFirst: false);
    _lastRefreshTime = DateTime.now();
  }

  /// Load next page → pakai paginated service
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _currentPage >= _lastPage) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final pageData = await _svc.fetchPaginatedEvents(
        page: nextPage,
        perPage: 10,
        forceRefresh: true,
      );

      _events.addAll(pageData.items);
      _currentPage = pageData.currentPage;
      _lastPage = pageData.lastPage;
      _hasMore = pageData.hasMore;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void selectEvent(Event event, BuildContext context) {
    _selectedEvent = event;
    notifyListeners();
  }

  void clearSelected() {
    _selectedEvent = null;
    notifyListeners();
  }

  // Tracks the last refresh time for cooldown
  DateTime? _lastRefreshTime;
  static const _refreshCooldown = Duration(minutes: 5);

  /// Check if enough time has passed since the last refresh
  bool shouldRefreshOnResume() {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!) > _refreshCooldown;
  }

  void clearAll() {
    _events = [];
    _selectedEvent = null;
    _error = null;
    _hasMore = false;
    _currentPage = 1;
    _lastPage = 1;
    notifyListeners();
  }
}
