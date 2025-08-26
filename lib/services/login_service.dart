import 'package:dio/dio.dart';

import '../models/login_model.dart';
import 'api_client.dart'; // central dio config
import 'user_service.dart'; // untuk save token
import '../config/logger.dart'; // optional, untuk logging

class AuthService {
  final Dio _dio = ApiClient.dio;

  /// Login dengan email & password
  Future<AuthResponse?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final auth = AuthResponse.fromJson(response.data);

        // ✅ simpan token ke local storage
        await UserService.saveToken(auth.token);
        return auth;
      } else {
        final data = response.data;
        final errorMessage =
            data['message'] ??
            (data['errors']?.values.first.first ?? 'Login gagal');
        throw Exception(errorMessage);
      }
    } catch (e) {
      logger.e("Login error: $e");
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  /// Register user baru
  Future<AuthResponse?> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final auth = AuthResponse.fromJson(response.data);

        // ✅ simpan token kalau API mengembalikan token
        if (auth.token.isNotEmpty) {
