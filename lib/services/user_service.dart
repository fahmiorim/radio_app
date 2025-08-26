import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:radio_odan_app/config/api_client.dart';
import 'package:radio_odan_app/models/user_model.dart';
import 'package:radio_odan_app/config/logger.dart';

class UserService {
  static const String _userKey = 'user_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Ambil token dari secure storage
  static Future<String?> getToken() async {
    return await _storage.read(key: _userKey);
  }

  /// Simpan token setelah login
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _userKey, value: token);
  }

  /// Hapus token saat logout
  static Future<void> clearToken() async {
    await _storage.delete(key: _userKey);
  }

  /// Ambil data profil user
  static Future<UserModel?> getProfile() async {
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
          return UserModel.fromJson(body['data']);
        }
      }
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'Gagal mengambil profil';
      if (data is Map<String, dynamic>) {
        msg = data['message'] ?? msg;
      }
      logger.e("Error getProfile: $msg");
      return null;
    } catch (e) {
      logger.e("Error getProfile: $e");
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

      final formData = FormData.fromMap({
        'name': name,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (avatarPath != null && avatarPath.isNotEmpty)
          'avatar': await MultipartFile.fromFile(avatarPath),
      });

      logger.d('Sending update profile request...');
      final response = await ApiClient.dio.put(
        '/profile',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      logger.d('Update profile response: ${response.data}');

      // Handle different possible response structures
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          // Handle case where success is in the response
          if (responseData['success'] == true) {
            return {
              'success': true,
              'data': responseData['data'] ?? responseData,
              'message':
                  responseData['message'] ?? 'Profil berhasil diperbarui',
            };
          }
          // Handle case where there's no explicit success field but has data
          if (responseData['data'] != null) {
            return {
              'success': true,
              'data': responseData['data'],
              'message':
                  responseData['message'] ?? 'Profil berhasil diperbarui',
            };
          }
        }
        // If we get here, the response structure is unexpected
        return {
          'success': true,
          'data': responseData,
          'message': 'Profil berhasil diperbarui',
        };
      }

      // If we get here, the request was not successful
      return {
        'success': false,
        'message': response.data['message'] ?? 'Gagal memperbarui profil',
        'data': response.data,
      };
    } on DioException catch (e) {
      logger.e('Error updateProfile: ${e.message}');
      logger.e('Error response: ${e.response?.data}');

      String message = 'Terjadi kesalahan saat memperbarui profil';
      if (e.response?.data != null) {
        if (e.response!.data is Map<String, dynamic>) {
          message = e.response!.data['message'] ?? message;

          // Handle Laravel validation errors
          if (e.response!.data['errors'] != null) {
            final errors = e.response!.data['errors'] as Map<String, dynamic>;
            message = errors.values.first is List
                ? (errors.values.first as List).first.toString()
                : errors.values.join('\n');
          }
        } else if (e.response!.data is String) {
          message = e.response!.data;
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
