import 'package:dio/dio.dart';

import '../config/app_api_config.dart';
import '../models/artikel_model.dart';

class ArtikelService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppApiConfig.baseUrl));

  Future<List<Artikel>> fetchArtikel() async {
    try {
      final response = await _dio.get('/news');

      if (response.statusCode == 200 && response.data['status'] == true) {
        List<dynamic> artikelList = response.data['data'];
        return artikelList.map((json) => Artikel.fromJson(json)).toList();
      } else {
        throw Exception("Gagal mengambil data artikel");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}
