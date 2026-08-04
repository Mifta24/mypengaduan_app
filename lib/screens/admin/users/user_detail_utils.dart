import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';

/// Shared data-extraction and formatting helpers for the admin user detail
/// and user-complaints screens. The backend response shape for a user
/// detail isn't fully consistent across endpoints, so most lookups try a
/// handful of possible keys before falling back.

int toIntValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool toBoolValue(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final normalized = value.toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'aktif';
  }
  return false;
}

int firstInt(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    if (!source.containsKey(key)) continue;
    return toIntValue(source[key]);
  }
  return 0;
}

String firstString(Map<String, dynamic> source, List<String> keys,
    {String fallback = '-'}) {
  for (final key in keys) {
    final value = source[key];
    if (value != null && value.toString().trim().isNotEmpty)
      return value.toString();
  }
  return fallback;
}

Map<String, dynamic>? firstMap(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return null;
}

Map<String, dynamic>? firstMapFromList(
    Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
  }
  return null;
}

DateTime? parseUserDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value)?.toLocal();
  return null;
}

List<Map<String, dynamic>> extractComplaintList(Map<String, dynamic> source) {
  const listKeys = [
    'complaints',
    'latest_complaints',
    'recent_complaints',
    'user_complaints'
  ];
  for (final key in listKeys) {
    final value = source[key];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }
  return const [];
}

int countComplaintsByStatus(Map<String, dynamic> source, Set<String> statuses) {
  final normalizedTargets = statuses.map((e) => e.toLowerCase()).toSet();

  const mapKeys = [
    'complaints_by_status',
    'complaint_status_counts',
    'status_counts',
    'statistics',
    'stats'
  ];
  for (final key in mapKeys) {
    final value = source[key];
    if (value is Map) {
      final counts = Map<String, dynamic>.from(value);
      var total = 0;
      for (final target in normalizedTargets) {
        total += toIntValue(counts[target]);
      }
      if (total > 0) return total;
    }
  }

  final complaints = extractComplaintList(source);
  if (complaints.isEmpty) return 0;
  return complaints.where((complaint) {
    final status = complaint['status']?.toString().toLowerCase() ?? '';
    return normalizedTargets.contains(status);
  }).length;
}

String formatUserDate(dynamic value) {
  final date = parseUserDate(value);
  if (date == null) return '-';
  return DateFormat('d MMMM y').format(date);
}

String userTimeAgo(dynamic value) {
  final date = parseUserDate(value);
  if (date == null) return '-';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return formatUserDate(date);
}

String complaintStatusText(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 'Pending';
    case 'processing':
    case 'in_progress':
      return 'Dalam Proses';
    case 'resolved':
    case 'completed':
      return 'Selesai';
    case 'rejected':
      return 'Ditolak';
    default:
      return status;
  }
}

Color complaintStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return AppTheme.warning;
    case 'processing':
    case 'in_progress':
      return const Color(0xFF0891B2);
    case 'resolved':
    case 'completed':
      return AppTheme.primary;
    case 'rejected':
      return AppTheme.danger;
    default:
      return Colors.grey;
  }
}
