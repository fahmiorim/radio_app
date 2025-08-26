import 'package:dio/dio.dart';

import '../config/app_api_config.dart';
import '../models/event_model.dart';

class EventService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppApiConfig.baseUrl));

  Future<List<Event>> fetchEvents() async {
    try {
      final response = await _dio.get('/event');

      if (response.statusCode == 200 && response.data['status'] == true) {
        List<dynamic> eventList = response.data['data'];
        return eventList.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception("Gagal mengambil data event");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }
}
