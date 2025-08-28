import 'package:flutter/material.dart';
import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/models/program_model.dart';
import 'package:radio_odan_app/services/program_service.dart';

class ProgramProvider with ChangeNotifier {
  final ProgramService _programService = ProgramService();
  
  // State for today's programs
  List<Program> _todaysPrograms = [];
  bool _isLoadingTodays = false;
  String? _todaysError;
  
  // State for all programs with pagination
  List<Program> _allPrograms = [];
  bool _isLoadingAll = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _perPage = 10;
  String? _allProgramsError;
  
  // Selected program state
  Program? _selectedProgram;
  bool _isLoadingDetail = false;
  String? _detailError;

  // Getters
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

  /// Fetch today's programs
  Future<void> fetchTodaysPrograms({bool forceRefresh = false}) async {
    if (_isLoadingTodays && !forceRefresh) return;
    
    _isLoadingTodays = true;
    _todaysError = null;
    notifyListeners();

    try {
      final programs = await _programService.fetchTodaysPrograms();
      _todaysPrograms = programs;
      _todaysError = null;
    } catch (e) {
      _todaysError = e.toString();
      debugPrint('Error fetching today\'s programs: $e');
    } finally {
      _isLoadingTodays = false;
      notifyListeners();
    }
  }

  /// Fetch all programs with pagination
  Future<void> fetchAllPrograms({bool loadMore = false}) async {
    if ((_isLoadingAll && !loadMore) || (_isLoadingMore && loadMore)) return;
    
    if (loadMore) {
      _isLoadingMore = true;
    } else {
      _isLoadingAll = true;
      _currentPage = 1;
      _allProgramsError = null;
    }
    
    notifyListeners();

    try {
      final result = await _programService.fetchAllPrograms(
        page: _currentPage,
        perPage: _perPage,
      );
      
      if (loadMore) {
        _allPrograms.addAll(result['programs'] as List<Program>);
      } else {
        _allPrograms = result['programs'] as List<Program>;
      }
      
      _hasMore = result['hasMore'] as bool;
      _currentPage = result['currentPage'] as int;
      _allProgramsError = null;
    } catch (e) {
      _allProgramsError = e.toString();
      debugPrint('Error fetching all programs: $e');
      
      if (loadMore) {
        _currentPage--; // Rollback page on error
      }
    } finally {
      _isLoadingAll = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Load more programs (pagination)
  Future<void> loadMorePrograms() async {
    if (_isLoadingMore || !_hasMore) return;
    _currentPage++;
    await fetchAllPrograms(loadMore: true);
  }

  /// Fetch program by ID
  Future<Program> fetchProgramById(int id) async {
    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();

    try {
      final program = await _programService.fetchProgramById(id);
      _selectedProgram = program;
      _detailError = null;
      return program;
    } catch (e) {
      _detailError = e.toString();
      debugPrint('Error fetching program $id: $e');
      rethrow;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Set selected program and navigate to detail
  void selectProgram(Program program, BuildContext context) {
    _selectedProgram = program;
    notifyListeners();
    Navigator.of(context).pushNamed(AppRoutes.programDetail);
  }

  /// Clear selected program
  void clearSelectedProgram() {
    _selectedProgram = null;
    _detailError = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      fetchTodaysPrograms(forceRefresh: true),
      fetchAllPrograms(),
    ]);
  }
}
