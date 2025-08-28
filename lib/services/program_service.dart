import 'package:dio/dio.dart';
import 'dart:developer' as developer;

import '../models/program_model.dart';
import '../config/api_client.dart';

class ProgramService {
  final Dio _dio = ApiClient.dio;
  static const String _tag = 'ProgramService';

  /// Fetch today's programs
  Future<List<Program>> fetchTodaysPrograms() async {
    try {
      developer.log('Fetching today\'s programs', name: _tag);
      final response = await _dio.get('/program-siaran');

      if (response.statusCode == 200 && response.data['status'] == true) {
        List<dynamic> programList = response.data['data'] ?? [];
        developer.log('Fetched ${programList.length} programs for today', name: _tag);
        return programList.map((json) => Program.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Gagal mengambil data program siaran hari ini');
      }
    } on DioException catch (e) {
      developer.log('DioError fetching today\'s programs: ${e.message}', name: _tag, error: e);
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      developer.log('Error fetching today\'s programs', name: _tag, error: e);
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Fetch all programs
  Future<Map<String, dynamic>> fetchAllPrograms({int page = 1, int perPage = 10}) async {
    try {
      developer.log('Fetching all programs', name: _tag);
      
      final response = await _dio.get('/program-siaran/semua');

      if (response.statusCode == 200 && response.data['status'] == true) {
        final List<dynamic> programList = response.data['data'] ?? [];
        
        developer.log('Fetched ${programList.length} programs', name: _tag);

        return {
          'programs': programList.map((json) => Program.fromJson(json)).toList(),
          'currentPage': 1,
          'lastPage': 1,
          'total': programList.length,
          'hasMore': false, // No pagination in this API
        };
      } else {
        throw Exception(response.data['message'] ?? 'Gagal mengambil daftar program');
      }
    } on DioException catch (e) {
      developer.log('DioError fetching all programs: ${e.message}', name: _tag, error: e);
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      developer.log('Error fetching all programs', name: _tag, error: e);
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Fetch program details by ID
  Future<Program> fetchProgramById(int id) async {
    try {
      developer.log('Fetching program details for ID: $id', name: _tag);
      
      final response = await _dio.get('/program-siaran/$id');

      if (response.statusCode == 200 && response.data['status'] == true) {
        developer.log('Successfully fetched program details for ID: $id', name: _tag);
        return Program.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Gagal mengambil detail program');
      }
    } on DioException catch (e) {
      developer.log('DioError fetching program $id: ${e.message}', name: _tag, error: e);
      if (e.response?.statusCode == 404) {
        throw Exception('Program tidak ditemukan');
      }
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      developer.log('Error fetching program $id', name: _tag, error: e);
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}
