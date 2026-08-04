import 'package:flutter/foundation.dart';

class Complaint {
  final int id;
  final int? userId; // Made nullable
  final int? categoryId; // Made nullable
  final String title;
  final String description;
  final String location;
  final String status;
  final String visibility;
  final String? priority;
  final String? photo;
  final String? photoUrl;
  final String? response;
  final String? adminResponse;
  final DateTime? estimatedResolution;
  final DateTime reportDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ComplaintResponse> responses;
  final Category? category;
  final List<Attachment>? attachments;

  Complaint({
    required this.id,
    this.userId, // Made optional
    this.categoryId, // Made optional
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    this.visibility = 'public',
    this.priority,
    this.photo,
    this.photoUrl,
    this.response,
    this.adminResponse,
    this.estimatedResolution,
    required this.reportDate,
    required this.createdAt,
    required this.updatedAt,
    this.responses = const [],
    this.category,
    this.attachments,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    try {
      // Parse category_id safely
      int? categoryId;
      if (json['category_id'] != null) {
        categoryId = json['category_id'] is int
            ? json['category_id'] as int
            : int.tryParse(json['category_id'].toString());
      } else if (json['category'] != null && json['category']['id'] != null) {
        categoryId = json['category']['id'] is int
            ? json['category']['id'] as int
            : int.tryParse(json['category']['id'].toString());
      }

      // Parse user_id safely
      int? userId;
      if (json['user_id'] != null) {
        userId = json['user_id'] is int
            ? json['user_id'] as int
            : int.tryParse(json['user_id'].toString());
      }

      return Complaint(
        id: json['id'] is int
            ? json['id'] as int
            : int.parse(json['id'].toString()),
        userId: userId,
        categoryId: categoryId,
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        visibility: _parseVisibility(json),
        priority: json['priority']?.toString(),
        photo: json['photo']?.toString(),
        photoUrl: json['photo_url']?.toString(),
        response: json['response']?.toString(),
        adminResponse: json['admin_response']?.toString(),
        estimatedResolution: json['estimated_resolution'] != null
            ? DateTime.tryParse(json['estimated_resolution'].toString())
            : null,
        reportDate: json['report_date'] != null
            ? DateTime.tryParse(json['report_date'].toString()) ??
                DateTime.now()
            : DateTime.now(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        responses: json['responses'] is List
            ? (json['responses'] as List)
                .whereType<Map>()
                .map((item) =>
                    ComplaintResponse.fromJson(Map<String, dynamic>.from(item)))
                .toList()
            : const [],
        category: json['category'] != null && json['category'] is Map
            ? Category.fromJson(json['category'] as Map<String, dynamic>)
            : null,
        attachments: json['attachments'] != null && json['attachments'] is List
            ? (json['attachments'] as List)
                .map(
                    (item) => Attachment.fromJson(item as Map<String, dynamic>))
                .toList()
            : null,
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing Complaint: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  static String _parseVisibility(Map<String, dynamic> json) {
    final value = json['visibility']?.toString().toLowerCase();
    if (value == 'private') return 'private';
    if (value == 'public') return 'public';

    final isPublic = json['is_public'];
    if (isPublic == false || isPublic == 0 || isPublic == '0') {
      return 'private';
    }
    return 'public';
  }

  bool get isPublic => visibility == 'public';

  String get visibilityText => isPublic ? 'Publik' : 'Privat';

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'in_progress':
        return 'Diproses';
      case 'waiting_user_confirmation':
        return 'Menunggu Konfirmasi Anda';
      case 'resolved':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }
}

class ComplaintResponse {
  final int id;
  final int? userId;
  final String message;
  final String userName;
  final String? userRole;
  final bool isAdmin;
  final DateTime createdAt;

  ComplaintResponse({
    required this.id,
    this.userId,
    required this.message,
    required this.userName,
    this.userRole,
    required this.isAdmin,
    required this.createdAt,
  });

  factory ComplaintResponse.fromJson(Map<String, dynamic> json) {
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : null;
    final role = (json['role'] ?? user?['role'])?.toString();
    final isAdmin = json['is_admin'] == true ||
        json['is_admin'] == 1 ||
        (role?.toLowerCase() == 'admin');

    return ComplaintResponse(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: parseNullableInt(json['user_id'] ?? user?['id']),
      message: (json['message'] ?? json['content'] ?? json['response'] ?? '')
          .toString(),
      userName: (json['user_name'] ??
              user?['name'] ??
              (isAdmin ? 'Admin' : 'Pengguna'))
          .toString(),
      userRole: role,
      isAdmin: isAdmin,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Category {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      return Category(
        id: json['id'] is int
            ? json['id'] as int
            : int.parse(json['id'].toString()),
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        isActive: json['is_active'] == 1 ||
            json['is_active'] == true ||
            json['is_active'] == null,
      );
    } catch (e) {
      debugPrint('Error parsing Category: $e');
      debugPrint('JSON: $json');
      rethrow;
    }
  }
}

class Attachment {
  final int id;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final String? mimeType;

  Attachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    this.mimeType,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    try {
      final resolvedPath = (json['file_url'] ??
              json['file_path'] ??
              json['url'] ??
              json['path'] ??
              '')
          .toString();

      return Attachment(
        id: json['id'] is int
            ? json['id'] as int
            : int.parse(json['id'].toString()),
        fileName: json['file_name']?.toString() ?? '',
        filePath: resolvedPath,
        fileType: json['file_type']?.toString() ?? '',
        fileSize: json['file_size'] is int
            ? json['file_size'] as int
            : int.tryParse(json['file_size']?.toString() ?? '0') ?? 0,
        mimeType: json['mime_type']?.toString(),
      );
    } catch (e) {
      debugPrint('Error parsing Attachment: $e');
      debugPrint('JSON: $json');
      rethrow;
    }
  }

  String get fileUrl => filePath;

  bool get isVideo {
    final mime = mimeType?.toLowerCase() ?? '';
    final name = fileName.toLowerCase();
    return mime.startsWith('video/') ||
        name.endsWith('.mp4') ||
        name.endsWith('.mov') ||
        name.endsWith('.webm') ||
        name.endsWith('.avi');
  }
}
