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
  int _totalItems = 0;
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

  Future<void> load({bool cacheFirst = true}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();

    try {
      // For initial load, use fetchRecentEvents
      final recentEvents = await _svc.fetchRecentEvents(forceRefresh: !cacheFirst);
      
      _events = recentEvents;
      _currentPage = 1;
      _lastPage = 1;
      _totalItems = recentEvents.length;
      _hasMore = recentEvents.length >= 10; // If we got 10 items, there might be more
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(cacheFirst: false);

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _currentPage >= _lastPage) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _svc.fetchPaginatedEvents(
        page: nextPage,
        perPage: 10,
        forceRefresh: true,
      );
      
      final newEvents = List<Event>.from(response['events']);
      _events.addAll(newEvents);
      _currentPage = response['currentPage'] ?? nextPage;
      _lastPage = response['lastPage'] ?? _lastPage;
      _totalItems = response['total'] ?? _totalItems;
      _hasMore = response['hasMore'] ?? false;
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading more events: $e');
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

  void clearAll() {
    _events = [];
    _selectedEvent = null;
    _error = null;
    _hasMore = false;
    _currentPage = 1;
    _lastPage = 1;
    _totalItems = 0;
    notifyListeners();
  }
}
