import 'package:dio/dio.dart';

import '../models/album_model.dart';
import '../models/album_detail_model.dart';
import '../config/api_client.dart';

class AlbumService {
  final Dio _dio = ApiClient.dio;

  // Fetch featured albums (limited number)
  Future<List<AlbumModel>> fetchFeaturedAlbums() async {
    try {
      print('Fetching featured albums...');
      final response = await _dio.get('/galeri');
      print('Featured albums response status: ${response.statusCode}');
      print('Featured albums response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true) {
          final albums = (data['data'] as List).map((item) {
            print('Featured album item: $item');
            return AlbumModel.fromJson(item);
          }).toList();
          print('Parsed ${albums.length} featured albums');
          return albums;
        }
      }
      return [];
    } catch (e) {
      throw Exception('Gagal memuat album: $e');
    }
  }

  // Fetch all albums with pagination
  Future<Map<String, dynamic>> fetchAllAlbums({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      print('Fetching all albums page $page, per page $perPage');
      final response = await _dio.get(
        '/galeri/semua',
        queryParameters: {'page': page, 'per_page': perPage, 'with_photos': 'true'},
      );
      print('All albums response status: ${response.statusCode}');
      print('All albums response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true) {
          return {
            'albums': (data['data'] as List)
                .map((json) => AlbumModel.fromJson(json))
                .toList(),
            'currentPage': data['pagination']?['current_page'] ?? 1,
            'lastPage': data['pagination']?['last_page'] ?? 1,
            'total': data['pagination']?['total'] ?? 0,
          };
        }
      }
      return {'albums': [], 'currentPage': 1, 'lastPage': 1, 'total': 0};
    } catch (e) {
      throw Exception('Gagal memuat daftar album: $e');
    }
  }

  // Fetch album detail with photos
  Future<AlbumDetailModel> fetchAlbumDetail(String slug) async {
    try {
      print('Fetching album detail for slug: $slug');
      final response = await _dio.get('/galeri/$slug');
      print('Album detail response status: ${response.statusCode}');
      print('Album detail response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true && data['data'] != null) {
          return AlbumDetailModel.fromJson(data['data']);
        } else {
          print('Invalid album data format: ${data['message']}');
          throw Exception(data['message'] ?? 'Data album tidak valid');
        }
      }
      throw Exception('Gagal memuat detail album: ${response.statusCode}');
    } catch (e) {
      print('Error in fetchAlbumDetail: $e');
      throw Exception('Gagal memuat detail album: ${e.toString()}');
    }
  }
}
