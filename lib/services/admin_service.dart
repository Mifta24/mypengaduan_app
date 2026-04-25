import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/api_response.dart';
import 'auth_service.dart';
import 'cache_service.dart';

class AdminService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: AppConfig.connectionTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    contentType: 'application/json',
  ))..interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      requestHeader: true,
      responseHeader: false,
    ),
  );
  final AuthService _authService = AuthService();

  Future<void> _setAuthHeader() async {
    final token = await _authService.getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  // ========== DASHBOARD ==========
  
  /// Get dashboard data
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/dashboard');
      
      // Check if response is HTML (token expired)
      if (response.data is String && (response.data as String).contains('<!DOCTYPE html>')) {
        debugPrint('❌ getDashboard: Received HTML response - Token expired!');
        throw Exception('Token expired - Please login again');
      }
      
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get quick stats with caching
  Future<Map<String, dynamic>> getQuickStats({bool forceRefresh = false}) async {
    const cacheKey = 'quick_stats';
    
    // Try to get from cache first if not forcing refresh
    if (!forceRefresh) {
      final cached = await CacheService.get(cacheKey);
      if (cached != null) {
        return cached as Map<String, dynamic>;
      }
    }
    
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/dashboard/quick-stats');
      
      // Check if response is HTML (token expired)
      if (response.data is String && (response.data as String).contains('<!DOCTYPE html>')) {
        debugPrint('❌ getQuickStats: Received HTML response - Token expired!');
        throw Exception('Token expired - Please login again');
      }
      
      // Cache for 2 minutes
      await CacheService.set(cacheKey, response.data, ttl: const Duration(minutes: 2));
      
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ========== COMPLAINT MANAGEMENT ==========
  
  /// Get all complaints with filters and smaller default pagination
  Future<Map<String, dynamic>> getComplaints({
    int page = 1,
    int perPage = 10, // Reduced from 15 to 10
    String? status,
    String? priority,
    String? search,
    int? userId,
    int? categoryId,
  }) async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/complaints', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (search != null) 'search': search,
        if (userId != null) 'user_id': userId,
        if (categoryId != null) 'category_id': categoryId,
      });
      
      // Check if response is HTML (token expired)
      if (response.data is String && (response.data as String).contains('<!DOCTYPE html>')) {
        debugPrint('❌ getComplaints: Received HTML response - Token expired!');
        throw Exception('Token expired - Please login again');
      }
      
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get complaint statistics
  Future<Map<String, dynamic>> getComplaintStatistics() async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/complaints/statistics');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get complaint by ID
  Future<Map<String, dynamic>> getComplaint(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/complaints/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Create complaint on behalf of user (admin scope)
  Future<ApiResponse> createComplaint(Map<String, dynamic> data) async {
    try {
      await _setAuthHeader();
      final response = await _dio.post('admin/complaints', data: data);
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Update complaint (admin full update)
  Future<ApiResponse> updateComplaint(int id, Map<String, dynamic> data) async {
    try {
      await _setAuthHeader();
      final response = await _dio.put('admin/complaints/$id', data: data);
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Update complaint status
  Future<ApiResponse> updateComplaintStatus(int id, String status, {String? notes}) async {
    try {
      await _setAuthHeader();
      final response = await _dio.patch('admin/complaints/$id/status', data: {
        'status': status,
        if (notes != null) 'notes': notes,
      });
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Mark complaint as resolved with resolution response and photos
  Future<ApiResponse> markComplaintAsResolved(
    int id, {
    required String resolution,
    List<String>? photos,
  }) async {
    try {
      await _setAuthHeader();

      final formData = FormData.fromMap({
        // Backend expects "resolution_response" field name
        'resolution_response': resolution,
      });

      if (photos != null && photos.isNotEmpty) {
        debugPrint('📎 [AdminService] Uploading ${photos.length} resolution photos');
        for (final path in photos) {
          final normalizedPath = path.replaceAll('\\\\', '/');
          final fileName = normalizedPath.split('/').last;
          formData.files.add(
            MapEntry(
              'resolution_photos[]',
              await MultipartFile.fromFile(path, filename: fileName),
            ),
          );
        }
      }

      final response = await _dio.post(
        'admin/complaints/$id/resolve',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
          contentType: 'multipart/form-data',
        ),
      );
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Add response to complaint
  Future<ApiResponse> addComplaintResponse(int id, String response) async {
    try {
      await _setAuthHeader();
      final res = await _dio.post('admin/complaints/$id/response', data: {
        'message': response,  // Backend expects "message" field
      });
      return ApiResponse.fromJson(res.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete complaint
  Future<ApiResponse> deleteComplaint(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.delete('admin/complaints/$id');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Bulk update complaints
  Future<ApiResponse> bulkUpdateComplaints(List<int> ids, String action, {String? value}) async {
    try {
      await _setAuthHeader();
      final response = await _dio.post('admin/complaints/bulk-update', data: {
        'ids': ids,
        'action': action,
        if (value != null) 'value': value,
      });
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Get trashed complaints
  Future<Map<String, dynamic>> getTrashedComplaints({
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      await _setAuthHeader();
      final response = await _dio.get(
        'admin/complaints/trashed',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Restore soft-deleted complaint
  Future<ApiResponse> restoreComplaint(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.post('admin/complaints/$id/restore');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Permanently delete complaint
  Future<ApiResponse> forceDeleteComplaint(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.delete('admin/complaints/$id/force-delete');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete specific complaint attachment
  Future<ApiResponse> deleteComplaintAttachment(int attachmentId) async {
    try {
      await _setAuthHeader();
      final response = await _dio.delete('admin/complaints/attachments/$attachmentId');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  // ========== CATEGORY MANAGEMENT ==========
  
  /// Get all categories
  Future<List<dynamic>> getCategories() async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/categories');
      return response.data['data'] as List;
    } catch (e) {
      rethrow;
    }
  }

  /// Get active categories only
  Future<List<dynamic>> getActiveCategories() async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/categories/active');
      return response.data['data'] as List;
    } catch (e) {
      rethrow;
    }
  }

  /// Get category by ID
  Future<Map<String, dynamic>> getCategory(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/categories/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Create category
  Future<ApiResponse> createCategory(Map<String, dynamic> data) async {
    try {
      await _setAuthHeader();
      final response = await _dio.post('admin/categories', data: data);
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Update category
  Future<ApiResponse> updateCategory(int id, Map<String, dynamic> data) async {
    try {
      await _setAuthHeader();
      final response = await _dio.put('admin/categories/$id', data: data);
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete category
  Future<ApiResponse> deleteCategory(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.delete('admin/categories/$id');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle category status
  Future<ApiResponse> toggleCategoryStatus(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.patch('admin/categories/$id/toggle-status');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Bulk action for categories
  Future<ApiResponse> bulkActionCategories({
    required List<int> ids,
    required String action,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await _setAuthHeader();
      final response = await _dio.post(
        'admin/categories/bulk-action',
        data: {
          'ids': ids,
          'action': action,
          ...?payload,
        },
      );
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  // ========== USER MANAGEMENT ==========
  
  /// Get all users with filters
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int perPage = 15,
    String? role,
    String? search,
  }) async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/users', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (role != null) 'role': role,
        if (search != null) 'search': search,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user by ID
  Future<Map<String, dynamic>> getUser(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/users/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Create user
  Future<ApiResponse> createUser(Map<String, dynamic> data) async {
    try {
      await _setAuthHeader();
      final response = await _dio.post('admin/users', data: data);
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user
  Future<ApiResponse> updateUser(int id, Map<String, dynamic> data) async {
    try {
      await _setAuthHeader();
      final response = await _dio.put('admin/users/$id', data: data);
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete user
  Future<ApiResponse> deleteUser(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.delete('admin/users/$id');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify user email
  Future<ApiResponse> verifyUserEmail(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.patch('admin/users/$id/verify-email');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Unverify user email
  Future<ApiResponse> unverifyUserEmail(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.patch('admin/users/$id/unverify-email');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify user account
  Future<ApiResponse> verifyUser(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.patch('admin/users/$id/verify-user');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Reject user verification
  Future<ApiResponse> rejectUserVerification(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.patch('admin/users/$id/reject-verification');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Change user role
  Future<ApiResponse> changeUserRole(int id, String role) async {
    try {
      await _setAuthHeader();
      final response = await _dio.patch('admin/users/$id/change-role', data: {
        'role': role,
      });
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Reset user password
  Future<ApiResponse> resetUserPassword(int id, String newPassword) async {
    try {
      await _setAuthHeader();
      final response = await _dio.patch('admin/users/$id/reset-password', data: {
        'password': newPassword,
        'password_confirmation': newPassword,
      });
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  // ========== ANNOUNCEMENT MANAGEMENT ==========
  
  /// Get all announcements with filters
  Future<Map<String, dynamic>> getAnnouncements({
    int page = 1,
    int perPage = 15,
    String? status,
    String? search,
  }) async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/announcements', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (status != null) 'status': status,
        if (search != null) 'search': search,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get announcement by ID
  Future<Map<String, dynamic>> getAnnouncement(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/announcements/$id');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Create announcement
  Future<ApiResponse> createAnnouncement(Map<String, dynamic> data, {String? imagePath}) async {
    try {
      await _setAuthHeader();
      
      dynamic requestData = data;
      Options? options;

      if (imagePath != null && imagePath.isNotEmpty) {
        final formData = FormData.fromMap(data);
        final normalizedPath = imagePath.replaceAll('\\\\', '/');
        final fileName = normalizedPath.split('/').last;
        formData.files.add(
          MapEntry(
            'image', 
            await MultipartFile.fromFile(imagePath, filename: fileName),
          ),
        );
        requestData = formData;
        options = Options(
          headers: {'Accept': 'application/json'},
          contentType: 'multipart/form-data',
        );
      }

      final response = await _dio.post('admin/announcements', data: requestData, options: options);
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Update announcement
  Future<ApiResponse> updateAnnouncement(int id, Map<String, dynamic> data, {String? imagePath}) async {
    try {
      await _setAuthHeader();
      
      dynamic requestData = data;
      Options? options;

      if (imagePath != null && imagePath.isNotEmpty) {
        // Laravel requires POST with _method=PUT for multipart form data updates
        final formDataMap = Map<String, dynamic>.from(data);
        formDataMap['_method'] = 'PUT';
        final formData = FormData.fromMap(formDataMap);
        
        final normalizedPath = imagePath.replaceAll('\\\\', '/');
        final fileName = normalizedPath.split('/').last;
        formData.files.add(
          MapEntry(
            'image', 
            await MultipartFile.fromFile(imagePath, filename: fileName),
          ),
        );
        
        requestData = formData;
        options = Options(
          headers: {'Accept': 'application/json'},
          contentType: 'multipart/form-data',
        );
        
        final response = await _dio.post('admin/announcements/$id', data: requestData, options: options);
        return ApiResponse.fromJson(response.data, null);
      } else {
        final response = await _dio.put('admin/announcements/$id', data: requestData);
        return ApiResponse.fromJson(response.data, null);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete announcement
  Future<ApiResponse> deleteAnnouncement(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.delete('admin/announcements/$id');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle announcement status
  Future<ApiResponse> toggleAnnouncementStatus(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.patch('admin/announcements/$id/toggle-status');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle announcement sticky
  Future<ApiResponse> toggleAnnouncementSticky(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.patch('admin/announcements/$id/toggle-sticky');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Publish announcement
  Future<ApiResponse> publishAnnouncement(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.post('admin/announcements/$id/publish');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Unpublish announcement
  Future<ApiResponse> unpublishAnnouncement(int id) async {
    try {
      await _setAuthHeader();
      final response = await _dio.post('admin/announcements/$id/unpublish');
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  // ========== REPORT MANAGEMENT ==========
  
  /// Get report overview
  Future<Map<String, dynamic>> getReportOverview() async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/reports/overview');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get complaints report
  Future<Map<String, dynamic>> getComplaintsReport({
    String? dateFrom,
    String? dateTo,
    String? status,
    int? categoryId,
    int? userId,
    String? priority,
    int? perPage,
    int? page,
  }) async {
    try {
      await _setAuthHeader();
      final response = await _dio.get(
        'admin/reports/complaints',
        queryParameters: {
          if (dateFrom != null) 'date_from': dateFrom,
          if (dateTo != null) 'date_to': dateTo,
          if (status != null) 'status': status,
          if (categoryId != null) 'category_id': categoryId,
          if (userId != null) 'user_id': userId,
          if (priority != null) 'priority': priority,
          if (perPage != null) 'per_page': perPage,
          if (page != null) 'page': page,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get users report
  Future<Map<String, dynamic>> getUsersReport({
    String? dateFrom,
    String? dateTo,
    String? role,
    bool? isActive,
    String? search,
    int? perPage,
    int? page,
  }) async {
    try {
      await _setAuthHeader();
      final response = await _dio.get(
        'admin/reports/users',
        queryParameters: {
          if (dateFrom != null) 'date_from': dateFrom,
          if (dateTo != null) 'date_to': dateTo,
          if (role != null) 'role': role,
          if (isActive != null) 'is_active': isActive ? 1 : 0,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (perPage != null) 'per_page': perPage,
          if (page != null) 'page': page,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}

