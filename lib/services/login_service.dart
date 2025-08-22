import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_api_config.dart';
import '../models/login_model.dart';

class AuthService {
  Future<AuthResponse?> loginWithGoogle(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('${AppApiConfig.baseUrl}/login/google'),
        body: {'token': idToken},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AuthResponse.fromJson(data);
      } else {
        print('Login Google gagal: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error AuthService loginWithGoogle: $e');
      return null;
    }
  }
}
