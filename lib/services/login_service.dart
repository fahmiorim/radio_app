import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_api_config.dart';
import '../models/login_model.dart';

class AuthService {
  final String _baseUrl = AppApiConfig.baseUrl;

  Future<AuthResponse?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AuthResponse.fromJson(data);
      } else {
        print('Login gagal: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error AuthService login: $e');
      return null;
    }
  }

  Future<AuthResponse?> register(
      String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        body: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AuthResponse.fromJson(data);
      } else {
        print('Registrasi gagal: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error AuthService register: $e');
      return null;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/forgot-password'),
        body: {'email': email},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Forgot password gagal: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error AuthService forgotPassword: $e');
      return false;
    }
  }

  Future<AuthResponse?> loginWithGoogle(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login/google'),
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

  Future<AuthResponse?> loginWithFacebook(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login/facebook'),
        body: {'token': accessToken},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AuthResponse.fromJson(data);
      } else {
        print('Login Facebook gagal: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error AuthService loginWithFacebook: $e');
      return null;
    }
  }
}
