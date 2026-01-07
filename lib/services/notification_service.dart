import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/api_response.dart';
import '../models/notification_model.dart';
import 'auth_service.dart';

class NotificationService {
  final Dio _dio;
  final AuthService _authService;

  NotificationService(this._authService) : _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: AppConfig.connectionTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
  ));

  Future<Options> _getOptions() async {
    final token = await _authService.getToken();
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
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        'notifications',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (status != null) 'status': status,
          if (type != null) 'type': type,
        },
        options: options,
      );

      return PaginatedResponse.fromJson(
        response.data,
        (item) => NotificationModel.fromJson(item),
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Failed to load notifications');
      }
      throw Exception('Network error: ${e.message}');
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

  // Register FCM token
  Future<bool> registerFCMToken(String fcmToken) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        'device-tokens',
        data: {
          'device_token': fcmToken,
          'device_type': 'android',
          'device_name': 'Mobile Device',
          'app_version': AppConfig.appVersion,
        },
        options: options,
      );

      return response.data['success'] as bool;
    } catch (e) {
      return false;
    }
  }
}
