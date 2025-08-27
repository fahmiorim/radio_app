import 'package:dio/dio.dart';
import '../models/video_model.dart';
import '../config/api_client.dart';

class VideoService {
  final Dio _dio = ApiClient.dio;

  Future<Map<String, dynamic>> fetchVideos({int page = 1, int perPage = 10}) async {
    try {
      final response = await _dio.get(
        '/video',
        queryParameters: {'page': page, 'per_page': perPage},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true) {
          return {
            'videos': (data['data'] as List)
                .map((video) => VideoModel.fromJson(video))
                .toList(),
            'pagination': data['pagination'] ?? {}
          };
        }
      }
      return {'videos': <VideoModel>[], 'pagination': {}};
    } catch (e) {
      throw Exception('Gagal memuat video: $e');
    }
  }

  Future<Map<String, dynamic>> fetchAllVideos({int page = 1, int perPage = 10}) async {
    try {
      final response = await _dio.get(
        '/video/semua',
        queryParameters: {'page': page, 'per_page': perPage},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true) {
          return {
            'videos': (data['data'] as List)
                .map((video) => VideoModel.fromJson(video))
                .toList(),
            'pagination': data['pagination'] ?? {}
          };
        }
      }
      return {'videos': <VideoModel>[], 'pagination': {}};
    } catch (e) {
      throw Exception('Gagal memuat semua video: $e');
    }
  }

  Future<VideoModel> fetchVideoDetail(int id) async {
    try {
      final response = await _dio.get('/video/$id');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true) {
          return VideoModel.fromJson(data['data']);
        }
      }
      throw Exception('Gagal memuat detail video');
    } catch (e) {
      throw Exception('Gagal memuat detail video: $e');
    }
  }
}
