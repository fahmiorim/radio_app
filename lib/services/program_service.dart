import 'package:dio/dio.dart';

import '../config/app_api_config.dart';
import '../models/program_model.dart';

class ProgramService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppApiConfig.baseUrl));

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
