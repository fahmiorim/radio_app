import 'package:dio/dio.dart';
import '../models/artikel_model.dart';
import '../config/api_client.dart';

class ArtikelService {
  final Dio _dio = ApiClient.dio;

  // Fetch recent articles (without pagination)
  Future<List<Artikel>> fetchRecentArtikel() async {
    try {
      final response = await _dio.get('/news/semua', queryParameters: {
        'per_page': 5, // Only get 5 recent articles for the home screen
        'page': 1,
      });

      if (response.statusCode == 200 && response.data['status'] == true) {
        List<dynamic> artikelList = response.data['data'];
        return artikelList.map((json) => Artikel.fromJson(json)).toList();
      } else {
        throw Exception("Gagal mengambil data artikel terbaru");
      }
    } catch (e) {
      print('Error in fetchRecentArtikel: $e');
      rethrow;
    }
  }

  // Fetch all articles with pagination
  Future<Map<String, dynamic>> fetchAllArtikel({int page = 1, int perPage = 20}) async {
    try {
      final response = await _dio.get(
        '/news/semua',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        final data = response.data;
        return {
          'data': (data['data'] as List)
              .map((json) => Artikel.fromJson(json))
              .toList(),
          'currentPage': data['pagination']['current_page'] ?? page,
          'lastPage': data['pagination']['last_page'] ?? 1,
          'total': data['pagination']['total'] ?? 0,
        };
      } else {
        throw Exception("Gagal mengambil data semua artikel");
      }
    } catch (e) {
      print('Error in fetchAllArtikel: $e');
      rethrow;
    }
  }
}
