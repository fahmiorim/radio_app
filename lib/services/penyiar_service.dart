import 'package:dio/dio.dart';

import '../config/app_api_config.dart';
import '../models/penyiar_model.dart';

class PenyiarService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppApiConfig.baseUrl));

  Future<List<Penyiar>> fetchPenyiar() async {
    try {
      final response = await _dio.get('/penyiar');

      if (response.statusCode == 200 && response.data['status'] == true) {
        List<dynamic> penyiarList = response.data['data'];
        return penyiarList.map((json) => Penyiar.fromJson(json)).toList();
      } else {
        throw Exception("Gagal mengambil data penyiar");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}
