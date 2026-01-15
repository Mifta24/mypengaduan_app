import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/api_response.dart';
import 'auth_service.dart';

class AdminService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: AppConfig.connectionTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
  ));
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
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get quick stats
  Future<Map<String, dynamic>> getQuickStats() async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/dashboard/quick-stats');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ========== COMPLAINT MANAGEMENT ==========
  
  /// Get all complaints with filters
  Future<Map<String, dynamic>> getComplaints({
    int page = 1,
    int perPage = 15,
    String? status,
    String? priority,
    String? search,
  }) async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/complaints', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (search != null) 'search': search,
      });
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

  /// Mark complaint as resolved
  Future<ApiResponse> markComplaintAsResolved(int id, {String? resolution}) async {
    try {
      await _setAuthHeader();
      final response = await _dio.post('admin/complaints/$id/resolve', data: {
        if (resolution != null) 'resolution': resolution,
      });
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
        'response': response,
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
  Future<ApiResponse> createAnnouncement(Map<String, dynamic> data) async {
    try {
      await _setAuthHeader();
      final response = await _dio.post('admin/announcements', data: data);
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }

  /// Update announcement
  Future<ApiResponse> updateAnnouncement(int id, Map<String, dynamic> data) async {
    try {
      await _setAuthHeader();
      final response = await _dio.put('admin/announcements/$id', data: data);
      return ApiResponse.fromJson(response.data, null);
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
  Future<Map<String, dynamic>> getComplaintsReport() async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/reports/complaints');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get users report
  Future<Map<String, dynamic>> getUsersReport() async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('admin/reports/users');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Export report
  Future<ApiResponse> exportReport(String type, {Map<String, dynamic>? filters}) async {
    try {
      await _setAuthHeader();
      final response = await _dio.post('admin/reports/export', data: {
        'type': type,
        if (filters != null) ...filters,
      });
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      rethrow;
    }
  }
}

