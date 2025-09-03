import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:radio_odan_app/config/api_client.dart';
import 'package:radio_odan_app/models/user_model.dart';
import 'package:radio_odan_app/config/logger.dart';

class UserService {
  static const _kUserTokenKey = 'user_token';
  static const _kUserDataKey = 'user_data';
  static const _kUserFetchedAtKey = 'user_fetched_at';
  static const _ttl = Duration(minutes: 5);

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static UserModel? _cachedUser;

  static Future<String?> getToken() => _storage.read(key: _kUserTokenKey);

  static Future<void> saveToken(String token) =>
      _storage.write(key: _kUserTokenKey, value: token);

  static Future<void> clearToken() async {
    _cachedUser = null;
    await _storage.delete(key: _kUserTokenKey);
    await _storage.delete(key: _kUserDataKey);
    await _storage.delete(key: _kUserFetchedAtKey);
  }

  static Future<UserModel?> getProfile({bool forceRefresh = false}) async {
    try {
      final token = await getToken();
      if (token == null) {
        logger.w("Token tidak ada, user belum login.");
        return null;
      }

      if (!forceRefresh) {
        final cached = await _readCachedUserIfFresh();
        if (cached != null) {
          _refreshProfileSilently();
          return cached;
        }
      }

      // Hit API
      final res = await ApiClient.I.dio.get('/user');
      if (res.statusCode == 200) {
        final body = res.data;
        if (body is Map && body['status'] == true && body['data'] != null) {
          final user = UserModel.fromJson(
            Map<String, dynamic>.from(body['data']),
          );
          await _writeCachedUser(user);
          return _cachedUser = user;
        }
      }

      // Fallback ke cache kalau ada
      return await _readCachedUser();
    } on DioException catch (e) {
      logger.e("Error getProfile: ${e.message}");
      return await _readCachedUser();
    } catch (e) {
      logger.e("Unexpected error in getProfile: $e");
      return await _readCachedUser();
    }
  }

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

      final trimmedName = name.trim();
      final trimmedEmail = email.trim();
      if (trimmedName.isEmpty || trimmedEmail.isEmpty) {
        throw Exception('Nama dan email harus diisi');
      }

      logger.d(
        '📤 Update profile: name=$trimmedName, email=$trimmedEmail, phone=$phone, address=$address, hasAvatar=${avatarPath != null}',
      );

      final formData = FormData.fromMap({
        '_method': 'PUT',
        'name': trimmedName,
        'email': trimmedEmail,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (address != null && address.trim().isNotEmpty)
          'address': address.trim(),
        if (avatarPath != null && avatarPath.trim().isNotEmpty)
          'avatar': await MultipartFile.fromFile(avatarPath.trim()),
      });

      final started = DateTime.now();
      final res = await ApiClient.I.dio.post('/profile', data: formData);
      logger.d(
        '✅ Response ${res.statusCode} in ${DateTime.now().difference(started).inMilliseconds}ms',
      );

      final data = res.data;
      if ((res.statusCode == 200 || res.statusCode == 201) && data is Map) {
        final payload = (data['status'] == true && data['data'] is Map)
            ? Map<String, dynamic>.from(data['data'])
            : Map<String, dynamic>.from(data);

        final user = UserModel.fromJson(payload);
        await _writeCachedUser(user);

        return {
          'success': true,
          'data': user,
          'message': data['message'] ?? 'Profil berhasil diperbarui',
        };
      }

      return {
        'success': false,
        'message': (data is Map && data['message'] != null)
            ? data['message']
            : 'Gagal memperbarui profil',
        'data': data,
      };
    } on DioException catch (e) {
      logger.e('❌ API Error: ${e.message}');
      String message = 'Terjadi kesalahan saat memperbarui profil';
      final rd = e.response?.data;
      if (rd != null) {
        if (rd is Map<String, dynamic>) {
          message = rd['message'] ?? message;
          if (rd['errors'] != null) {
            final errors = rd['errors'] as Map<String, dynamic>;
            message = errors.values.first is List
                ? (errors.values.first as List).first.toString()
                : errors.values.join(', ');
          }
        } else if (rd is String) {
          message = rd;
        }
      }
      return {
        'success': false,
        'message': message,
        'error': e.toString(),
        'statusCode': e.response?.statusCode,
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

  static Future<void> logout() async {
    try {
      await ApiClient.I.dio.post('/logout');
    } catch (e) {
      // kalau gagal pun, tetap bersihkan token lokal
      logger.w("Logout warning: $e");
    } finally {
      await clearToken();
    }
  }

  static Future<void> _writeCachedUser(UserModel user) async {
    _cachedUser = user;
    await _storage.write(key: _kUserDataKey, value: jsonEncode(user.toJson()));
    await _storage.write(
      key: _kUserFetchedAtKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  static Future<UserModel?> _readCachedUser() async {
    if (_cachedUser != null) return _cachedUser;
    final raw = await _storage.read(key: _kUserDataKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw);
      return _cachedUser = UserModel.fromJson(Map<String, dynamic>.from(map));
    } catch (e) {
      logger.e("Error parsing cached user data: $e");
      return null;
    }
  }

  static Future<UserModel?> _readCachedUserIfFresh() async {
    final fetchedAtStr = await _storage.read(key: _kUserFetchedAtKey);
    if (fetchedAtStr == null) return null;
    final fetchedAt = DateTime.tryParse(fetchedAtStr);
    if (fetchedAt == null) return null;
    if (DateTime.now().difference(fetchedAt) >= _ttl) return null;
    return await _readCachedUser();
  }

  static Future<void> _refreshProfileSilently() async {
    try {
      final res = await ApiClient.I.dio.get(
        '/user',
        options: Options(headers: {'Cache-Control': 'no-cache'}),
      );
      if (res.statusCode == 200) {
        final body = res.data;
        if (body is Map && body['status'] == true && body['data'] != null) {
          final user = UserModel.fromJson(
            Map<String, dynamic>.from(body['data']),
          );
          await _writeCachedUser(user);
        }
      }
    } catch (_) {}
  }
}
