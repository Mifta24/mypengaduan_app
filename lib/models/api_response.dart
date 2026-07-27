import 'package:flutter/foundation.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    try {
      return ApiResponse<T>(
        success: json['success'] == true || json['success'] == 1,
        message: json['message']?.toString() ?? '',
        data: json['data'] != null && fromJsonT != null
            ? fromJsonT(json['data'])
            : json['data'],
      );
    } catch (e) {
      debugPrint('Error parsing ApiResponse: $e');
      debugPrint('JSON: $json');
      rethrow;
    }
  }
}

class PaginatedResponse<T> {
  final bool success;
  final String message;
  final PaginationMeta meta;
  final List<T> data;
  final int? unreadCount;

  PaginatedResponse({
    required this.success,
    required this.message,
    required this.meta,
    required this.data,
    this.unreadCount,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    try {
      return PaginatedResponse<T>(
        success: json['success'] == true || json['success'] == 1,
        message: json['message']?.toString() ?? '',
        meta: PaginationMeta.fromJson(
            json['meta'] as Map<String, dynamic>? ?? const {}),
        data: (json['data'] as List? ?? const [])
            .map((item) => fromJsonT(item))
            .toList(),
        unreadCount: json['unread_count'] != null
            ? (json['unread_count'] is int
                ? json['unread_count'] as int
                : int.tryParse(json['unread_count'].toString()))
            : null,
      );
    } catch (e) {
      debugPrint('Error parsing PaginatedResponse: $e');
      debugPrint('JSON: $json');
      rethrow;
    }
  }
}

class PaginationMeta {
  final int currentPage;
  final int? from; // Made nullable - can be null when no data
  final int lastPage;
  final int perPage;
  final int? to; // Made nullable - can be null when no data
  final int total;

  PaginationMeta({
    required this.currentPage,
    this.from,
    required this.lastPage,
    required this.perPage,
    this.to,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    try {
      return PaginationMeta(
        currentPage: json['current_page'] is int
            ? json['current_page'] as int
            : int.tryParse(json['current_page']?.toString() ?? '') ?? 1,
        from: json['from'] != null
            ? (json['from'] is int
                ? json['from'] as int
                : int.tryParse(json['from'].toString()))
            : null,
        lastPage: json['last_page'] is int
            ? json['last_page'] as int
            : int.tryParse(json['last_page']?.toString() ?? '') ?? 1,
        perPage: json['per_page'] is int
            ? json['per_page'] as int
            : int.tryParse(json['per_page']?.toString() ?? '') ?? 20,
        to: json['to'] != null
            ? (json['to'] is int
                ? json['to'] as int
                : int.tryParse(json['to'].toString()))
            : null,
        total: json['total'] is int
            ? json['total'] as int
            : int.tryParse(json['total']?.toString() ?? '') ?? 0,
      );
    } catch (e) {
      debugPrint('Error parsing PaginationMeta: $e');
      debugPrint('JSON: $json');
      rethrow;
    }
  }

  bool get hasMorePages => currentPage < lastPage;
}
