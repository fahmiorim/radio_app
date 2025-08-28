import 'package:flutter/material.dart';
import 'package:radio_odan_app/config/app_routes.dart';
import 'package:radio_odan_app/models/program_model.dart';
import 'package:radio_odan_app/services/program_service.dart';

class ProgramProvider with ChangeNotifier {
  final ProgramService _programService = ProgramService();
  List<Program> _programs = [];
  Program? _selectedProgram;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  final int _perPage = 10;
  String? _error;

  List<Program> get programs => _programs;
  Program? get selectedProgram => _selectedProgram;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> fetchPrograms({bool forceRefresh = false}) async {
    if (_isLoadingMore) return;

    if (_programs.isNotEmpty && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _page = 1;
    _error = null;
    notifyListeners();

    try {
      final data = await _programService.fetchPrograms(
        page: _page,
        perPage: _perPage,
      );

      _programs = data;
      _hasMore = data.length == _perPage;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching programs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePrograms() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _page++;
    notifyListeners();

    try {
      final data = await _programService.fetchPrograms(
        page: _page,
        perPage: _perPage,
      );

      _programs.addAll(data);
      _hasMore = data.length == _perPage;
      _error = null;
    } catch (e) {
      _page--; // Rollback page on error
      _error = e.toString();
      debugPrint('Error loading more programs: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Set selected program and navigate to detail
  void selectProgram(Program program, BuildContext context) {
    _selectedProgram = program;
    notifyListeners();
    Navigator.of(context).pushNamed(AppRoutes.programDetail);
  }

  // Clear selected program
  void clearSelectedProgram() {
    _selectedProgram = null;
    notifyListeners();
  }

  // Fetch single program by ID
  Future<Program> fetchProgramById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final program = await _programService.fetchProgramById(id);
      _selectedProgram = program;
      _error = null;
      return program;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching program by ID: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch today's programs
  Future<void> fetchProgram() async {
    _isLoading = true;
    _page = 1;
    _error = null;
    notifyListeners();

    try {
      final data = await _programService.fetchProgram();
      _programs = data;
      _hasMore = false; // Since this is just for today's programs, no pagination
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching today\'s programs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
