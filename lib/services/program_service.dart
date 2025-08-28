import 'package:dio/dio.dart';

import '../models/program_model.dart';
import '../config/api_client.dart';

class ProgramService {
  final Dio _dio = ApiClient.dio;

  Future<List<Program>> fetchProgram() async {
    try {
      final response = await _dio.get('/program-siaran');

      if (response.statusCode == 200 && response.data['status'] == true) {
        List<dynamic> programList = response.data['data'];
        return programList.map((json) => Program.fromJson(json)).toList();
      } else {
        throw Exception("Gagal mengambil data program");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  Future<List<Program>> fetchPrograms({int page = 1, int perPage = 10}) async {
    try {
      print('Fetching programs - Page: $page, Per Page: $perPage');
      final response = await _dio.get(
        '/program-siaran/semua',
        queryParameters: {'page': page, 'per_page': perPage},
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        print('API Response: ${response.data}');
        List<dynamic> programList = response.data['data'] ?? [];
        print('Total programs received: ${programList.length}');
        return programList.map((json) => Program.fromJson(json)).toList();
      } else {
        print('API Error: ${response.data}');
        throw Exception("Gagal mengambil data program");
      }
    } catch (e) {
      print("Error fetching programs: $e");
      throw Exception("Error: $e");
    }
  }

  Future<Program> fetchProgramById(int id) async {
    try {
      final response = await _dio.get('/program-siaran/$id');

      if (response.statusCode == 200 && response.data['status'] == true) {
        return Program.fromJson(response.data['data']);
      } else {
        throw Exception('Gagal mengambil detail program');
      }
    } catch (e) {
      print('Error fetching program detail: $e');
      throw Exception('Gagal memuat detail program: $e');
    }
  }
}
