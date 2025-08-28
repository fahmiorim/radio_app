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

  /// Ambil data profil user
  static Future<UserModel?> getProfile({bool forceRefresh = false}) async {
    try {
      final token = await getToken();
      if (token == null) {
        logger.w("Token tidak ada, user belum login.");
        return null;
      }

      // Clear cache if force refresh is true
      if (forceRefresh) {
        _cachedUser = null;
        await _storage.delete(key: _userDataKey);
      }

      final response = await ApiClient.dio.get(
        '/user',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache',
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
      logger.d('🚀 Preparing to update profile with values:');
      logger.d('🔹 name: $trimmedName');
      logger.d('🔹 email: $trimmedEmail');
      logger.d('🔹 phone: $phone');
      logger.d('🔹 address: $address');
      logger.d('🔹 has avatar: ${avatarPath != null}');
      logger.d('🔹 API Endpoint: /profile (POST)');
      logger.d('🔹 Using token: ${token.substring(0, 10)}...');

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
      logger.d('📡 Sending profile update request...');
      final startTime = DateTime.now();
      
      final response = await ApiClient.dio.post(
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
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      logger.d('✅ Received response in ${duration.inMilliseconds}ms');
      logger.d('📥 Response status: ${response.statusCode}');
      logger.d('📥 Response data: ${response.data}');

      // Handle response
      final responseData = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData is Map<String, dynamic>) {
          // Update the cached user data
          if (responseData['status'] == true && responseData['data'] != null) {
            _cachedUser = UserModel.fromJson(
              responseData['data'] is Map<String, dynamic> 
                  ? responseData['data'] 
                  : responseData,
            );
            // Save to secure storage
            await _storage.write(
              key: _userDataKey,
              value: jsonEncode(_cachedUser?.toJson()),
            );
            
            return {
              'success': true,
              'data': _cachedUser,
              'message': responseData['message'] ?? 'Profil berhasil diperbarui',
            };
          }
        }
        return {
          'success': true,
          'data': responseData,
          'message': 'Profil berhasil diperbarui',
        };
      }

      // Handle error response
      return {
        'success': false,
        'message': (responseData is Map && responseData['message'] != null)
            ? responseData['message']
            : 'Gagal memperbarui profil',
        'data': responseData,
      };
    } on DioException catch (e) {
      logger.e('❌ API Error: ${e.message}');
      if (e.response != null) {
        logger.e('❌ Status code: ${e.response?.statusCode}');
        logger.e('❌ Response data: ${e.response?.data}');
        logger.e('❌ Headers: ${e.response?.headers}');
        
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
        
        return {
          'success': false, 
          'message': message,
          'error': e.toString(),
          'statusCode': e.response?.statusCode,
        };
      }
      
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server: ${e.message}',
        'error': e.toString(),
      };
    } catch (e) {
      logger.e('Unexpected error in updateProfile: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan yang tidak diketahui: $e',
        'error': e.toString(),
      };
    }
  }
}
