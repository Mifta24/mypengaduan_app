import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/api_response.dart';
import '../models/complaint_model.dart';
import 'auth_service.dart';

class ComplaintService {
  final Dio _dio;
  final AuthService _authService;

  ComplaintService(this._authService)
      : _dio = Dio(BaseOptions(
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

  // Get complaints with pagination
  Future<PaginatedResponse<Complaint>> getComplaints({
    int page = 1,
    int perPage = 15,
    String? status,
    int? categoryId,
    String? search,
  }) async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        'complaints',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (status != null) 'status': status,
          if (categoryId != null) 'category_id': categoryId,
          if (search != null) 'search': search,
        },
        options: options,
      );

      print('Get complaints response: ${response.data}');
      print('Total complaints: ${response.data['data']?.length ?? 0}');

      return PaginatedResponse.fromJson(
        response.data,
        (item) => Complaint.fromJson(item),
      );
    } on DioException catch (e) {
      print('Error loading complaints: ${e.response?.data ?? e.message}');
      if (e.response != null) {
        throw Exception(
            e.response!.data['message'] ?? 'Failed to load complaints');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get complaint detail
  Future<Complaint?> getComplaintDetail(int complaintId) async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        'complaints/$complaintId',
        options: options,
      );

      if (response.data['success']) {
        return Complaint.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get complaint detail raw response (used for richer UI sections)
  Future<Map<String, dynamic>?> getComplaintDetailRaw(int complaintId) async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        'complaints/$complaintId',
        options: options,
      );

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

  // Create complaint
  Future<ApiResponse<Complaint>> createComplaint({
    required int categoryId,
    required String title,
    required String description,
    required String location,
    required DateTime reportDate,
    List<String>? attachments,
    List<String>? videos,
  }) async {
    try {
      final token = await _authService.getToken();

      FormData formData = FormData.fromMap({
        'category_id': categoryId,
        'title': title,
        'description': description,
        'location': location,
        'report_date': reportDate.toIso8601String().split('T')[0],
      });

      // Add attachments if any
      if (attachments != null && attachments.isNotEmpty) {
        print('📎 Uploading ${attachments.length} attachments...');

        for (int i = 0; i < attachments.length; i++) {
          String fileName = attachments[i].split('/').last;
          formData.files.add(MapEntry(
            'attachments[]',
            await MultipartFile.fromFile(attachments[i], filename: fileName),
          ));
        }
      } else {
        print('📎 No attachments to upload');
      }

      // Add videos if any
      if (videos != null && videos.isNotEmpty) {
        print('🎥 Uploading ${videos.length} videos...');
        for (final path in videos) {
          final fileName = path.split('/').last;
          formData.files.add(MapEntry(
            'videos[]',
            await MultipartFile.fromFile(path, filename: fileName),
          ));
        }
      }

      print('📤 Sending request to backend...');
      print('📤 Content-Type: multipart/form-data');
      print('📤 Endpoint: complaints');

      final response = await _dio.post(
        'complaints',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('✅ Create complaint response: ${response.data}');
      print(
          '📎 Response has attachments field: ${response.data['data']?.containsKey('attachments')}');
      print(
          '📎 Response attachments value: ${response.data['data']?['attachments']}');

      return ApiResponse.fromJson(
        response.data,
        (json) => Complaint.fromJson(json),
      );
    } on DioException catch (e) {
      print('❌ Error creating complaint: ${e.message}');
      print('❌ Error response: ${e.response?.data}');
      print('❌ Error status: ${e.response?.statusCode}');
      if (e.response != null) {
        return ApiResponse.fromJson(e.response!.data, null);
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Update complaint (only allowed while still pending on backend)
  Future<ApiResponse<Complaint>> updateComplaint({
    required int id,
    required int categoryId,
    required String title,
    required String description,
    required String location,
    required DateTime reportDate,
    List<String>? attachments,
    List<String>? videos,
  }) async {
    try {
      final token = await _authService.getToken();

      FormData formData = FormData.fromMap({
        'category_id': categoryId,
        'title': title,
        'description': description,
        'location': location,
        'report_date': reportDate.toIso8601String().split('T')[0],
        '_method': 'PUT',
      });

      // Add new attachments if any (existing ones are kept by backend)
      if (attachments != null && attachments.isNotEmpty) {
        print('📎 Updating with ${attachments.length} new attachments...');
        for (int i = 0; i < attachments.length; i++) {
          String fileName = attachments[i].split('/').last;
          formData.files.add(MapEntry(
            'attachments[]',
            await MultipartFile.fromFile(attachments[i], filename: fileName),
          ));
        }
      }

      // Add new videos if any
      if (videos != null && videos.isNotEmpty) {
        print('🎥 Updating with ${videos.length} new videos...');
        for (final path in videos) {
          final fileName = path.split('/').last;
          formData.files.add(MapEntry(
            'videos[]',
            await MultipartFile.fromFile(path, filename: fileName),
          ));
        }
      }

      print('✏️ Updating complaint #$id...');
      final response = await _dio.post(
        'complaints/$id',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('✅ Update complaint response: ${response.data}');

      return ApiResponse.fromJson(
        response.data,
        (json) => Complaint.fromJson(json),
      );
    } on DioException catch (e) {
      print('❌ Error updating complaint: ${e.message}');
      print('❌ Error response: ${e.response?.data}');
      print('❌ Error status: ${e.response?.statusCode}');
      if (e.response != null) {
        return ApiResponse.fromJson(e.response!.data, null);
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // Get categories
  Future<List<Category>> getCategories() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        'complaints/categories',
        options: options,
      );

      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((item) => Category.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get complaint statistics
  Future<Map<String, dynamic>?> getStatistics() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        'complaints/statistics',
        options: options,
      );

      if (response.data['success']) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Track complaint timeline/status
  Future<Map<String, dynamic>?> trackComplaint(int complaintId) async {
    try {
      final options = await _getOptions();
      final response = await _dio.get(
        'complaints/$complaintId/track',
        options: options,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Add response/message to complaint thread (user scope)
  Future<ApiResponse> addResponse(int complaintId, String message) async {
    final data = {'message': message};
    final endpoint = 'complaints/$complaintId/responses';
    try {
      final options = await _getOptions();
      print('📤 [ComplaintService] POST $endpoint');
      final response = await _dio.post(
        endpoint,
        data: data,
        options: options,
      );
      print('✅ [ComplaintService] addResponse status: ${response.statusCode}');
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      print('❌ [ComplaintService] addResponse failed: ${e.response?.statusCode} ${e.requestOptions.path}');
      if (e.response?.statusCode == 404) {
        return ApiResponse(
          success: false,
          message:
              'Endpoint /api/complaints/{id}/responses tidak ditemukan di server.',
        );
      }

      if (e.response != null && e.response!.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(
          e.response!.data as Map<String, dynamic>,
          null,
        );
      }

      return ApiResponse(
        success: false,
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // Confirm complaint resolution (user scope)
  Future<ApiResponse> confirmResolution(int complaintId) async {
    try {
      final options = await _getOptions();
      final response = await _dio.post(
        'complaints/$complaintId/confirm-resolution',
        options: options,
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(
          e.response!.data as Map<String, dynamic>,
          null,
        );
      }
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // Delete complaint (user scope)
  Future<ApiResponse> deleteComplaint(int complaintId) async {
    try {
      final options = await _getOptions();
      final response = await _dio.delete(
        'complaints/$complaintId',
        options: options,
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(
            e.response!.data as Map<String, dynamic>, null);
      }
      return ApiResponse(
          success: false, message: 'Network error: ${e.message}');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }
}
