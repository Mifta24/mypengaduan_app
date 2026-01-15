import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/auth_response.dart';

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService() : _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: AppConfig.connectionTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  // Register
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required String address,
  }) async {
    try {
      final response = await _dio.post('auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'phone': phone,
        'address': address,
      });

      final authResponse = AuthResponse.fromJson(response.data);
      
      if (authResponse.success && authResponse.data != null) {
        await _saveToken(authResponse.data!.token);
        await _saveUser(authResponse.data!.user);
      }

      return authResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        return AuthResponse.fromJson(e.response!.data);
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Login
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('auth/login', data: {
        'email': email,
        'password': password,
      });

      print('=== AUTH SERVICE DEBUG ===');
      print('Response data: ${response.data}');
      print('User data: ${response.data['data']?['user']}');
      print('User role: ${response.data['data']?['user']?['role']}');
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      print('Parsed user: ${authResponse.data?.user.name}');
      print('Parsed role: ${authResponse.data?.user.role}');
      print('=== END DEBUG ===');
      
      if (authResponse.success && authResponse.data != null) {
        await _saveToken(authResponse.data!.token);
        await _saveUser(authResponse.data!.user);
      }

      return authResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        return AuthResponse.fromJson(e.response!.data);
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get Profile
  Future<User?> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _dio.get(
        'auth/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success']) {
        final user = User.fromJson(response.data['data']);
        await _saveUser(user);
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update Profile
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    required String address,
    String? nik,
    String? rtNumber,
    String? rwNumber,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final response = await _dio.put(
        'auth/profile',
        data: {
          'name': name,
          'phone': phone,
          'address': address,
          if (nik != null && nik.isNotEmpty) 'nik': nik,
          if (rtNumber != null && rtNumber.isNotEmpty) 'rt_number': rtNumber,
          if (rwNumber != null && rwNumber.isNotEmpty) 'rw_number': rwNumber,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success']) {
        final user = User.fromJson(response.data['data']);
        await _saveUser(user);
        return {
          'success': true,
          'message': response.data['message'] ?? 'Profile updated successfully',
          'user': user,
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to update profile',
      };
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response!.data['message'] ?? 'Failed to update profile',
          'errors': e.response!.data['errors'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    }
  }

  // Change Password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final response = await _dio.put(
        'auth/change-password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPasswordConfirmation,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return {
        'success': response.data['success'] ?? false,
        'message': response.data['message'] ?? 'Password changed successfully',
      };
    } on DioException catch (e) {
      if (e.response != null) {
        return {
          'success': false,
          'message': e.response!.data['message'] ?? 'Failed to change password',
          'errors': e.response!.data['errors'],
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.message}',
      };
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await _dio.post(
          'auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
      await _clearStorage();
      return true;
    } catch (e) {
      await _clearStorage();
      return true;
    }
  }

  // Save token
  Future<void> _saveToken(String token) async {
    await _storage.write(key: AppConfig.tokenKey, value: token);
  }

  // Get token
  Future<String?> getToken() async {
    return await _storage.read(key: AppConfig.tokenKey);
  }

  // Save user
  Future<void> _saveUser(User user) async {
    await _storage.write(
      key: AppConfig.userKey,
      value: jsonEncode(user.toJson()),
    );
  }

  // Get user from storage
  Future<User?> getUserFromStorage() async {
    try {
      final userJson = await _storage.read(key: AppConfig.userKey);
      if (userJson == null) return null;
      
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  // Clear storage
  Future<void> _clearStorage() async {
    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: AppConfig.userKey);
    await _storage.delete(key: AppConfig.fcmTokenKey);
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
