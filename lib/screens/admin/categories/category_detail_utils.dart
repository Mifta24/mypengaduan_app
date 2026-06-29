import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';

int categoryToInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool categoryToBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final s = value.toLowerCase();
    return s == '1' || s == 'true' || s == 'yes' || s == 'aktif';
  }
  return false;
}

String categoryComplaintStatusText(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 'Pending';
    case 'processing':
    case 'in_progress':
      return 'Dalam Proses';
    case 'resolved':
    case 'completed':
      return 'Selesai';
    default:
      return status;
  }
}

Color categoryComplaintStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return AppTheme.warning;
    case 'processing':
    case 'in_progress':
      return AppTheme.info;
    case 'resolved':
    case 'completed':
      return AppTheme.success;
    default:
      return AppTheme.textSecondary;
  }
}

DateTime? parseCategoryDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString())?.toLocal();
}

String categoryTimeAgo(dynamic value) {
  final date = parseCategoryDate(value);
  if (date == null) return '-';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return DateFormat('d MMM y').format(date);
}

String formatCategoryDate(dynamic value) {
  final date = parseCategoryDate(value);
  if (date == null) return '-';
  return DateFormat('d MMMM y, HH:mm').format(date);
}

String extractCategoryUserName(dynamic userObj) {
  if (userObj is Map) return userObj['name']?.toString() ?? '-';
  return '-';
}
