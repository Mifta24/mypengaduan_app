import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/announcement_model.dart';
import '../models/comment_model.dart';
import '../models/api_response.dart';
import 'auth_service.dart';

class AnnouncementService {
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
  /// Get all announcements with pagination
  Future<PaginatedResponse<Announcement>> getAnnouncements({
    int page = 1,
    int perPage = 15,
    String? priority,
  }) async {
    try {
      final response = await _dio.get(
        '/announcements',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (priority != null) 'priority': priority,
        },
      );

      return PaginatedResponse<Announcement>.fromJson(
        response.data,
        (json) => Announcement.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get urgent announcements
  Future<List<Announcement>> getUrgentAnnouncements() async {
    try {
      final response = await _dio.get('/announcements/urgent');
      
      final data = response.data['data'] as List;
      return data.map((json) => Announcement.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get latest announcements
  Future<List<Announcement>> getLatestAnnouncements({int limit = 5}) async {
    try {
      final response = await _dio.get(
        '/announcements/latest',
        queryParameters: {'limit': limit},
      );
      
      final data = response.data['data'] as List;
      return data.map((json) => Announcement.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get announcement detail
  Future<Announcement> getAnnouncementDetail(String idOrSlug) async {
    try {
      final response = await _dio.get('/announcements/$idOrSlug');
      
      return Announcement.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  // Note: Bookmark feature not yet implemented in backend
  // Uncomment when backend adds these endpoints:
  // - POST /announcements/{id}/bookmark
  // - GET /announcements/bookmarked
  
  // /// Toggle bookmark/save announcement
  // Future<ApiResponse> toggleBookmark(int announcementId) async {
  //   try {
  //     await _setAuthHeader();
  //     final response = await _dio.post('/announcements/$announcementId/bookmark');
  //     
  //     return ApiResponse(
  //       success: true,
  //       message: response.data['message'] ?? 'Bookmark toggled successfully',
  //       data: response.data['data'],
  //     );
  //   } catch (e) {
  //     return ApiResponse(
  //       success: false,
  //       message: e.toString(),
  //     );
  //   }
  // }

  // /// Get user's bookmarked announcements
  // Future<List<Announcement>> getBookmarkedAnnouncements() async {
  //   try {
  //     await _setAuthHeader();
  //     final response = await _dio.get('/announcements/bookmarked');
  //     
  //     final data = response.data['data'] as List;
  //     return data.map((json) => Announcement.fromJson(json)).toList();
  //   } catch (e) {
  //     rethrow;
  //   }
  // }

  // Note: Comment list endpoint now available!
  
  /// Get comments for an announcement
  Future<List<Comment>> getComments(int announcementId) async {
    try {
      // Ensure auth token is set
      await _setAuthHeader();
      
      final response = await _dio.get('/announcements/$announcementId/comments');
      
      // Check if response is HTML (authentication failed)
      if (response.data is String && response.data.toString().contains('<!DOCTYPE html>')) {
        throw Exception('Autentikasi gagal. Silakan login kembali.');
      }
      
      // Handle different response structures
      final dynamic data = response.data['data'] ?? response.data;
      
      if (data is List) {
        return data.map((json) => Comment.fromJson(json as Map<String, dynamic>)).toList();
      }
      
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Add comment to an announcement
  Future<ApiResponse> addComment(int announcementId, String content) async {
    try {
      await _setAuthHeader();
      final response = await _dio.post(
        '/announcements/$announcementId/comments',
        data: {'content': content},
      );
      
      // Don't parse comment data if not returned by backend
      return ApiResponse(
        success: true,
        message: response.data['message'] ?? 'Komentar berhasil dikirim',
        data: null,
      );
    } on DioException catch (e) {
      String errorMessage = 'Terjadi kesalahan';
      
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;
        
        if (statusCode == 422) {
          // Validation error
          if (data is Map && data['errors'] != null) {
            final errors = data['errors'] as Map;
            errorMessage = errors.values.first.toString();
          } else if (data is Map && data['message'] != null) {
            errorMessage = data['message'].toString();
          } else {
            errorMessage = 'Data tidak valid';
          }
        } else if (statusCode == 401) {
          errorMessage = 'Anda harus login terlebih dahulu';
        } else if (statusCode == 404) {
          errorMessage = 'Pengumuman tidak ditemukan';
        } else if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      } else {
        errorMessage = 'Tidak dapat terhubung ke server';
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // Note: Delete comment endpoint not yet implemented in backend
  // Uncomment when backend adds DELETE /announcements/{id}/comments/{commentId}
  
  // /// Delete comment
  // Future<ApiResponse> deleteComment(int announcementId, int commentId) async {
  //   try {
  //     await _setAuthHeader();
  //     final response = await _dio.delete(
  //       '/announcements/$announcementId/comments/$commentId',
  //     );
  //     
  //     return ApiResponse(
  //       success: true,
  //       message: response.data['message'] ?? 'Comment deleted successfully',
  //     );
  //   } catch (e) {
  //     return ApiResponse(
  //       success: false,
  //       message: e.toString(),
  //     );
  //   }
  // }
}
