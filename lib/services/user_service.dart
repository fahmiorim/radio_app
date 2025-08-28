import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:radio_odan_app/config/api_client.dart';
import 'package:radio_odan_app/models/user_model.dart';
import 'package:radio_odan_app/config/logger.dart';

class UserService {
  static const String _userKey = 'user_token';
  static const String _userDataKey = 'user_data';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static UserModel? _cachedUser;

  /// Ambil token dari secure storage
  static Future<String?> getToken() async {
    return await _storage.read(key: _userKey);
  }

  /// Simpan token setelah login
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _userKey, value: token);
  }

  /// Hapus token dan cache saat logout
  static Future<void> clearToken() async {
    _cachedUser = null;
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _userDataKey);
  }

  /// Ambil data profil user dengan caching
  static Future<UserModel?> getProfile({bool forceRefresh = false}) async {
    // Return cached user if available and not forcing refresh
    if (_cachedUser != null && !forceRefresh) {
      return _cachedUser;
    }

    try {
      final token = await getToken();
      if (token == null) {
        logger.w("Token tidak ada, user belum login.");
        return null;
      }

      final response = await ApiClient.dio.get(
        '/user',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final body = response.data;
        if (body['status'] == true && body['data'] != null) {
          _cachedUser = UserModel.fromJson(body['data']);
          // Save to secure storage for persistence
          await _storage.write(
            key: _userDataKey,
            value: jsonEncode(_cachedUser?.toJson()),
          );
          return _cachedUser;
        }
      }
      return null;
    } on DioException catch (e) {
      logger.e("Error getProfile: ${e.message}");
      // Try to load from cache if available
      final cachedData = await _storage.read(key: _userDataKey);
      if (cachedData != null) {
        try {
          _cachedUser = UserModel.fromJson(jsonDecode(cachedData));
          return _cachedUser;
        } catch (e) {
          logger.e("Error parsing cached user data: $e");
        }
      }
      return null;
    } catch (e) {
      logger.e("Unexpected error in getProfile: $e");
      return null;
    }
  }

  /// Logout dari API dan hapus token lokal
  static Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await ApiClient.dio.post(
          '/logout',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          ),
        );
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Logout gagal';
      if (data is Map<String, dynamic>) {
        msg = data['message'] ?? msg;
      }
      logger.w("Logout error: $msg");
    } catch (e) {
      logger.w("Logout error: $e");
    } finally {
      await clearToken(); // ✅ tetap hapus token biarpun API gagal
    }
  }

  /// Update profil user
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? address,
    String? avatarPath,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Token tidak tersedia. Silakan login kembali.');
      }

      // Trim & validate
      final trimmedName = name.trim();
      final trimmedEmail = email.trim();
      if (trimmedName.isEmpty || trimmedEmail.isEmpty) {
        throw Exception('Nama dan email harus diisi');
      }

      // Log values
      logger.d('Updating profile with values:');
      logger.d('- name: $trimmedName');
      logger.d('- email: $trimmedEmail');
      logger.d('- phone: $phone');
      logger.d('- address: $address');
      logger.d('- has avatar: ${avatarPath != null}');

      // Build form data dengan override method
      final formData = FormData.fromMap({
        '_method': 'PUT', // 👈 trik Laravel method override
        'name': trimmedName,
        'email': trimmedEmail,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (address != null && address.trim().isNotEmpty)
          'address': address.trim(),
        if (avatarPath != null && avatarPath.trim().isNotEmpty)
          'avatar': await MultipartFile.fromFile(avatarPath.trim()),
      });

      // Kirim sebagai POST
      final response = await ApiClient.dio.post(
        '/profile', // atau '/api/v1/mobile/profile' sesuai route kamu
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      logger.d('Update profile response: ${response.data}');

      // Handle sukses
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          if (responseData['status'] == true) {
            return {
              'success': true,
              'data': responseData['data'],
              'message':
                  responseData['message'] ?? 'Profil berhasil diperbarui',
            };
          }
        }
      }

      // Handle gagal
      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal memperbarui profil',
        'data': response.data,
      };
    } on DioException catch (e) {
      logger.e('Error updateProfile: ${e.message}');
      logger.e('Error response: ${e.response?.data}');

      String message = 'Terjadi kesalahan saat memperbarui profil';
      final responseData = e.response?.data;
      if (responseData != null) {
        if (responseData is Map<String, dynamic>) {
          message = responseData['message'] ?? message;

          // Laravel validation errors
          if (responseData['errors'] != null) {
            final errors = responseData['errors'] as Map<String, dynamic>;
            message = errors.values.first is List
                ? (errors.values.first as List).first.toString()
                : errors.values.join(', ');
          }
        } else if (responseData is String) {
          message = responseData;
        }
      }

      return {'success': false, 'message': message, 'error': e.toString()};
    } catch (e) {
      logger.e('Error updateProfile: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan yang tidak diketahui: $e',
      };
    }
  }
}
