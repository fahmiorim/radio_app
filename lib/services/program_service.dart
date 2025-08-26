import 'package:dio/dio.dart';

import '../models/program_model.dart';
import 'api_client.dart';

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
}
