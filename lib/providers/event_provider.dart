import 'package:flutter/material.dart';
import 'package:radio_odan_app/models/event_model.dart';
import 'package:radio_odan_app/services/event_service.dart';

class EventProvider with ChangeNotifier {
  final EventService _eventService = EventService();
  List<Event> _events = [];
  Event? _selectedEvent;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  final int _perPage = 10;
  String? _error;

  List<Event> get events => _events;
  Event? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> fetchEvents({bool forceRefresh = false}) async {
    if (_isLoadingMore) return;

    // Jika sudah ada data dan bukan force refresh, tidak perlu fetch ulang
    if (_events.isNotEmpty && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _page = 1;
    _error = null;
    notifyListeners();

    try {
      final data = await _eventService.fetchAllEvents(
        page: _page,
        perPage: _perPage,
      );
      
      _events = data;
      _hasMore = data.length == _perPage;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreEvents() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _page++;
      final newEvents = await _eventService.fetchAllEvents(
        page: _page,
        perPage: _perPage,
      );

      _events.addAll(newEvents);
      _hasMore = newEvents.length == _perPage;
    } catch (e) {
      _page--; // Rollback page on error
      _error = e.toString();
      debugPrint('Error loading more events: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void selectEvent(Event event, BuildContext context) {
    _selectedEvent = event;
    // Navigate to event detail or handle selection
    // Navigator.pushNamed(context, AppRoutes.eventDetail);
  }
}
