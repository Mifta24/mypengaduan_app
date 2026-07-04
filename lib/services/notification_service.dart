import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/api_response.dart';
import '../models/notification_model.dart';
import 'auth_service.dart';

class NotificationService {
  final Dio _dio;
  final AuthService _authService;
  CancelToken? _currentGetRequestToken;

  NotificationService(this._authService) : _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: AppConfig.connectionTimeout,
    receiveTimeout: const Duration(seconds: 30), // Reduced timeout for notifications
  )) {
    // Add interceptor for debugging
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('🌐 [Dio] REQUEST: ${options.method} ${options.baseUrl}${options.path}');
        debugPrint('📤 Headers: ${options.headers}');
        debugPrint('📤 Query: ${options.queryParameters}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('✅ [Dio] RESPONSE: ${response.statusCode}');
        debugPrint('📥 Data Type: ${response.data.runtimeType}');
        return handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('❌ [Dio] ERROR: ${error.type}');
        debugPrint('❌ Message: ${error.message}');
        debugPrint('❌ Response: ${error.response?.statusCode}');
        debugPrint('❌ Error Object: ${error.error}');
        return handler.next(error);
      },
    ));
  }
  
  // Cancel any ongoing GET request
  void cancelOngoingRequest() {
    if (_currentGetRequestToken != null && !_currentGetRequestToken!.isCancelled) {
      debugPrint('🚫 [NotificationService] Cancelling ongoing request');
      _currentGetRequestToken!.cancel('New request initiated');
    }
  }

  Future<Options> _getOptions() async {
    final token = await _authService.getToken();
    debugPrint('🔑 [NotificationService] Using token: ${token?.substring(0, 20)}...');
    
    // Try to get user info for debugging
    try {
      final user = await _authService.getUserFromStorage();
      if (user != null) {
        debugPrint('👤 [NotificationService] Current user: ID=${user.id}, Name=${user.name}, Role=${user.role}');
      }
    } catch (e) {
      debugPrint('⚠️ Could not get user info: $e');
    }
    
    return Options(headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
  }

  // Get notifications with pagination
  Future<PaginatedResponse<NotificationModel>> getNotifications({
    int page = 1,
    int perPage = 15,
    String? status,
    String? type,
  }) async {
    // Cancel any ongoing request first
    cancelOngoingRequest();
    
    // Create new cancel token
    _currentGetRequestToken = CancelToken();
    
    try {
      final options = await _getOptions();
      
      debugPrint('🔔 [NotificationService] Fetching notifications...');
      debugPrint('📍 URL: ${AppConfig.baseUrl}notifications');
      debugPrint('📄 Page: $page, PerPage: $perPage');
      
      final response = await _dio.get(
        'notifications',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (status != null) 'status': status,
          if (type != null) 'type': type,
        },
        options: options,
        cancelToken: _currentGetRequestToken,
      );

      debugPrint('✅ [NotificationService] Response received');
      debugPrint('📊 Status Code: ${response.statusCode}');
      
      // Check if response is HTML (login redirect)
      if (response.data is String && response.data.toString().contains('<!DOCTYPE html>')) {
        debugPrint('🚨 [NotificationService] Received HTML instead of JSON!');
        debugPrint('🚨 This means TOKEN IS EXPIRED or INVALID');
        throw DioException(
          requestOptions: RequestOptions(path: 'notifications'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: 'notifications'),
            statusCode: 401,
            data: {'message': 'Token expired'},
          ),
        );
      }
      
      debugPrint('📦 Response Data: ${response.data}');

      // Handle different response structures from backend
      Map<String, dynamic> responseData;
      
      if (response.data is Map<String, dynamic>) {
        responseData = response.data as Map<String, dynamic>;
        
        // Check if data is wrapped in 'data' key
        if (responseData.containsKey('data') && 
            responseData['data'] is Map<String, dynamic> &&
            (responseData['data'] as Map<String, dynamic>).containsKey('data')) {
          // Backend format: {success, message, data: {current_page, data: [], ...}}
          debugPrint('📦 Using nested data structure');
          final innerData = responseData['data'] as Map<String, dynamic>;
          responseData = {
            'success': responseData['success'],
            'message': responseData['message'],
            'data': innerData['data'],
            'meta': {
              'current_page': innerData['current_page'],
              'last_page': innerData['last_page'] ?? 1,
              'per_page': innerData['per_page'] ?? perPage,
              'total': innerData['total'] ?? 0,
              'from': innerData['from'],
              'to': innerData['to'],
            },
            'unread_count': responseData['unread_count'],
          };
        } else if (responseData.containsKey('data') && responseData['data'] is List) {
          // Backend format: {success, message, data: [...]}
          debugPrint('📦 Using direct list structure');
          responseData = {
            'success': responseData['success'],
            'message': responseData['message'],
            'data': responseData['data'],
            'meta': {
              'current_page': page,
              'last_page': 1,
              'per_page': perPage,
              'total': (responseData['data'] as List).length,
            },
          };
        }
      } else {
        throw Exception('Invalid response format from server');
      }

      debugPrint('📦 Final response data: $responseData');

      return PaginatedResponse.fromJson(
        responseData,
        (item) => NotificationModel.fromJson(item),
      );
    } on DioException catch (e) {
      debugPrint('❌ [NotificationService] DioException caught');
      debugPrint('Type: ${e.type}');
      debugPrint('Status Code: ${e.response?.statusCode}');
      debugPrint('Response Data: ${e.response?.data}');
      debugPrint('Error Message: ${e.message}');
      debugPrint('Error Object: ${e.error}');
      
      // Handle cancelled requests silently
      if (e.type == DioExceptionType.cancel) {
        debugPrint('🚫 Request was cancelled');
        throw Exception('Request cancelled');
      }
      
      // Handle specific error types
      if (e.type == DioExceptionType.receiveTimeout || 
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Koneksi timeout. Periksa koneksi internet Anda atau coba lagi nanti.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
      } else if (e.type == DioExceptionType.unknown) {
        // Unknown error - could be network, SSL, or other issues
        final errorDetail = e.error?.toString() ?? 'Unknown error';
        debugPrint('🔍 Unknown error detail: $errorDetail');
        
        if (errorDetail.contains('SocketException') || errorDetail.contains('NetworkException')) {
          throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
        } else if (errorDetail.contains('HandshakeException') || errorDetail.contains('CERTIFICATE')) {
          throw Exception('Masalah sertifikat SSL. Hubungi administrator.');
        } else {
          throw Exception('Terjadi kesalahan: $errorDetail');
        }
      } else if (e.response?.statusCode == 404) {
        throw Exception('Endpoint notifikasi tidak ditemukan di server.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      } else if (e.response != null) {
        final message = e.response!.data is Map 
            ? (e.response!.data['message'] ?? 'Gagal memuat notifikasi')
            : 'Gagal memuat notifikasi';
        throw Exception(message);
      }
      
      throw Exception('Terjadi kesalahan jaringan. Silakan coba lagi.');
    } catch (e) {
      debugPrint('❌ [NotificationService] Exception caught: $e');
      throw Exception('Gagal memuat notifikasi: ${e.toString()}');
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        'notifications/$notificationId/read',
        options: options,
      );

      return response.data['success'] as bool;
    } catch (e) {
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        'notifications/read-all',
        options: options,
      );

      return response.data['success'] as bool;
    } catch (e) {
      return false;
    }
  }

  // Delete a single notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final options = await _getOptions();
      final response = await _dio.delete(
        'notifications/$notificationId',
        options: options,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['success'] == true || data['success'] == 1;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // Register FCM token
  Future<bool> registerFCMToken(String fcmToken) async {
    try {
      final options = await _getOptions();
      debugPrint('🔑 Registering FCM token to backend: ${fcmToken.substring(0, 50)}...');
      
      final response = await _dio.post(
        'device-tokens',
        data: {
          'device_token': fcmToken,
          'device_type': 'android',
          'device_model': 'Android Device', // Changed from device_name
          'os_version': 'Android', // Added os_version
          'app_version': AppConfig.appVersion,
        },
        options: options,
      );

      debugPrint('✅ Backend response: ${response.data}');
      debugPrint('✅ Success: ${response.data['success']}');
      debugPrint('✅ Message: ${response.data['message']}');
      return response.data['success'] as bool? ?? true;
    } on DioException catch (e) {
      // Handle duplicate token (already registered) as success
      if (e.response?.statusCode == 500) {
        final errorMsg = e.response?.data?['message']?.toString() ?? '';
        if (errorMsg.contains('duplicate key') || errorMsg.contains('already exists')) {
          debugPrint('⚠️ Token already registered (duplicate key), treating as success');
          return true; // Token already exists, that's fine!
        }
      }
      
      debugPrint('❌ DioException registering token: ${e.response?.statusCode}');
      debugPrint('❌ Error data: ${e.response?.data}');
      debugPrint('❌ Error message: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Exception registering token: $e');
      return false;
    }
  }

  // Get registered device tokens for current user
  Future<List<Map<String, dynamic>>> getDeviceTokens() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get('device-tokens', options: options);

      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        final data = payload['data'];
        if (data is List) {
          return data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  // Delete a registered device token
  Future<bool> deleteDeviceToken(int id) async {
    try {
      final options = await _getOptions();
      final response = await _dio.delete('device-tokens/$id', options: options);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['success'] == true || data['success'] == 1;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // Get notification settings for current user
  Future<Map<String, dynamic>?> getNotificationSettings() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get('notification-settings', options: options);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Update notification settings for current user
  Future<bool> updateNotificationSettings(Map<String, dynamic> settings) async {
    try {
      final options = await _getOptions();
      final response = await _dio.put(
        'notification-settings',
        data: settings,
        options: options,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['success'] == true || data['success'] == 1;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
