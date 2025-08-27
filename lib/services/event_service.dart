import 'package:dio/dio.dart';

import '../models/event_model.dart';
import '../config/api_client.dart';

class EventService {
  final Dio _dio = ApiClient.dio;

  // Fetch all events with pagination
  Future<List<Event>> fetchAllEvents({int page = 1, int perPage = 10}) async {
    try {
      final response = await _dio.get(
        '/event/semua',
        queryParameters: {'page': page, 'per_page': perPage},
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        List<dynamic> eventList = response.data['data'];
        return eventList.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception("Gagal mengambil data semua event");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  // Fetch recent events (limited number)
  Future<List<Event>> fetchRecentEvents() async {
    try {
      final response = await _dio.get('/event');

      if (response.statusCode == 200 && response.data['status'] == true) {
        List<dynamic> eventList = response.data['data'];
        return eventList.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception("Gagal mengambil data event terbaru");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}
