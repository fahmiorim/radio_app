import 'package:dio/dio.dart';

import '../models/artikel_model.dart';
import 'api_client.dart';

class ArtikelService {
  final Dio _dio = ApiClient.dio;

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
