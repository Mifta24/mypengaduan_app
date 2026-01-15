import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/api_response.dart';
import '../models/complaint_model.dart';
import 'auth_service.dart';

class ComplaintService {
  final Dio _dio;
  final AuthService _authService;

  ComplaintService(this._authService) : _dio = Dio(BaseOptions(
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
        throw Exception(e.response!.data['message'] ?? 'Failed to load complaints');
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

  // Create complaint
  Future<ApiResponse<Complaint>> createComplaint({
    required int categoryId,
    required String title,
    required String description,
    required String location,
    required DateTime reportDate,
    List<String>? attachments,
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
        print('Uploading ${attachments.length} attachments...');
        for (int i = 0; i < attachments.length; i++) {
          String fileName = attachments[i].split('/').last;
          print('Adding attachment $i: $fileName from ${attachments[i]}');
          formData.files.add(MapEntry(
            'attachments[]',  // Changed from 'attachments[$i]' to 'attachments[]'
            await MultipartFile.fromFile(
              attachments[i],
              filename: fileName,
            ),
          ));
        }
        print('Total files in FormData: ${formData.files.length}');
      }

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

      print('Create complaint response: ${response.data}');
      return ApiResponse.fromJson(
        response.data,
        (json) => Complaint.fromJson(json),
      );
    } on DioException catch (e) {
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
}
