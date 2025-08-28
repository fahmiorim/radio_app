import 'package:dio/dio.dart';
import '../models/artikel_model.dart';
import '../config/api_client.dart';

class ArtikelService {
  static const String _basePath = '/news';
  final Dio _dio = ApiClient.dio;

  // Fetch recent articles (without pagination)
  Future<List<Artikel>> fetchRecentArtikel() async {
    try {
      final response = await _dio.get(_basePath);

      if (response.statusCode == 200 && response.data['status'] == true) {
        List<dynamic> artikelList = response.data['data'];
        return artikelList.map((json) => Artikel.fromJson(json)).toList();
      } else {
        throw Exception('Gagal mengambil data artikel terbaru');
      }
    } catch (e) {
      print('Error in fetchRecentArtikel: $e');
      rethrow;
    }
  }

  // Fetch all articles with pagination
  Future<Map<String, dynamic>> fetchAllArtikel({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _dio.get(
        '$_basePath/semua',
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
          'currentPage': data['current_page'] ?? 1,
          'lastPage': data['last_page'] ?? 1,
        };
      } else {
        throw Exception('Gagal mengambil data artikel');
      }
    } catch (e) {
      print('Error in fetchAllArtikel: $e');
      rethrow;
    }
  }

  // Fetch single article by slug
  Future<Artikel> fetchArtikelBySlug(String slug) async {
    try {
      final response = await _dio.get('$_basePath/$slug');

      if (response.statusCode == 200 && response.data['status'] == true) {
        return Artikel.fromJson(response.data['data']);
      } else if (response.statusCode == 404) {
        throw Exception('Artikel tidak ada');
      } else {
        throw Exception(
            'Gagal mengambil detail artikel. Kode status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Dio Error:');
      print('- Message: ${e.message}');
      print('- Type: ${e.type}');
      print('- Error: ${e.error}');
      print('- Response: ${e.response?.data}');
      
      if (e.response != null) {
        throw Exception(
            'Gagal mengambil detail artikel: ${e.response?.data['message'] ?? 'Tidak ada pesan error'}');
      } else {
        throw Exception(
            'Tidak dapat terhubung ke server. Pastikan koneksi internet Anda stabil.');
      }
    } catch (e) {
      print('Unexpected error in fetchArtikelBySlug: $e');
      rethrow;
    }
  }
}
