import 'dart:async';
import 'package:flutter/material.dart';
import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/models/program_model.dart';
import 'package:radio_odan_app/services/program_service.dart';

class ProgramProvider with ChangeNotifier {
  final ProgramService _svc = ProgramService.I;

  List<Program> _todaysPrograms = [];
  bool _isLoadingTodays = false;
  String? _todaysError;

  List<Program> _allPrograms = [];
  bool _isLoadingAll = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  final int _perPage = 10;
  String? _allProgramsError;

  Program? _selectedProgram;
  bool _isLoadingDetail = false;
  String? _detailError;

  bool _initialized = false;

  List<Program> get todaysPrograms => _todaysPrograms;
  List<Program> get allPrograms => _allPrograms;
  Program? get selectedProgram => _selectedProgram;

  bool get isLoadingTodays => _isLoadingTodays;
  bool get isLoadingAll => _isLoadingAll;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  bool get isLoadingDetail => _isLoadingDetail;

  String? get todaysError => _todaysError;
  String? get allProgramsError => _allProgramsError;
  String? get detailError => _detailError;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Load cached data first
    await fetchTodaysPrograms(forceRefresh: false);

    // Then refresh in background
    unawaited(refreshAll());
  }

  DateTime? _lastFetchAttempt;
  static const Duration _minFetchInterval = Duration(seconds: 30);

  Future<void> fetchTodaysPrograms({bool forceRefresh = false}) async {
    final now = DateTime.now();

    // Prevent too frequent requests
    if (_lastFetchAttempt != null &&
        now.difference(_lastFetchAttempt!) < _minFetchInterval &&
        !forceRefresh) {
      return;
    }

    if (_isLoadingTodays) {
      if (!forceRefresh) return;
      // If force refresh is true, we'll let it proceed even if already loading
    }

    _lastFetchAttempt = now;
    _isLoadingTodays = true;
    _todaysError = null;
    notifyListeners();

    try {
      final programs = await _svc.fetchTodaysPrograms(
        forceRefresh: forceRefresh,
      );
      _todaysPrograms = programs;
      _todaysError = null;
    } catch (e) {
      _todaysError = e.toString();

      // If we have cached data, don't show the error to the user
      if (_todaysPrograms.isNotEmpty) {
        _todaysError = null;
      }
    } finally {
      _isLoadingTodays = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllPrograms({
    bool loadMore = false,
    bool forceRefresh = false,
  }) async {
    if ((!loadMore && _isLoadingAll) || (loadMore && _isLoadingMore)) return;

    if (loadMore) {
      if (!_hasMore) return;
      _isLoadingMore = true;
    } else {
      _isLoadingAll = true;
      _currentPage = 1;
      _allProgramsError = null;
    }
    notifyListeners();

    try {
      final result = await _svc.fetchAllPrograms(
        page: _currentPage,
        perPage: _perPage,
        forceRefresh: forceRefresh,
      );

      final List<Program> fetched = (result['programs'] as List<Program>);
      final bool hasMore = (result['hasMore'] as bool?) ?? false;
      final int currentPage = (result['currentPage'] as int?) ?? 1;

      if (loadMore) {
        _allPrograms.addAll(fetched);
      } else {
        _allPrograms = fetched;
      }

      _hasMore = hasMore;
      _currentPage = currentPage;
      _allProgramsError = null;
    } catch (e) {
      _allProgramsError = e.toString();
      if (loadMore) {
        _currentPage = (_currentPage > 1) ? _currentPage - 1 : 1;
      }
    } finally {
      _isLoadingAll = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePrograms() async {
    if (_isLoadingMore || !_hasMore) return;
    _currentPage++;
    await fetchAllPrograms(loadMore: true);
  }

  Future<Program> fetchProgramById(int id, {bool forceRefresh = false}) async {
    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();

    try {
      final program = await _svc.fetchProgramById(
        id,
        forceRefresh: forceRefresh,
      );
      _selectedProgram = program;
      _detailError = null;
      return program;
    } catch (e) {
      _detailError = e.toString();
      rethrow;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  void selectProgram(Program program, BuildContext context) {
    _selectedProgram = program;
    notifyListeners();
    Navigator.of(context).pushNamed(AppRoutes.programDetail);
  }

  void clearSelectedProgram() {
    _selectedProgram = null;
    _detailError = null;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchTodaysPrograms(forceRefresh: true),
      fetchAllPrograms(forceRefresh: true),
    ]);
  }
}
