import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

int announcementToInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool announcementToBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final normalized = value.toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes' || normalized == 'aktif';
  }
  return false;
}

String firstAnnouncementString(Map<String, dynamic> source, List<String> keys, {String fallback = '-'}) {
  for (final key in keys) {
    final value = source[key];
    if (value != null && value.toString().trim().isNotEmpty) return value.toString();
  }
  return fallback;
}

String capitalizeAnnouncement(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

Color announcementPriorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'urgent':
      return AppTheme.danger;
    case 'high':
      return AppTheme.warning;
    case 'medium':
      return AppTheme.info;
    case 'low':
      return AppTheme.primary;
    default:
      return AppTheme.textSecondary;
  }
}

String formatAnnouncementDateTime(dynamic value) {
  if (value == null) return '-';
  final date = DateTime.tryParse(value.toString())?.toLocal();
  if (date == null) return value.toString();
  return DateFormat('d MMMM y, HH:mm').format(date);
}

bool isAnnouncementImageFile(String value) {
  final normalized = value.toLowerCase();
  return normalized.endsWith('.png') ||
      normalized.endsWith('.jpg') ||
      normalized.endsWith('.jpeg') ||
      normalized.endsWith('.webp') ||
      normalized.endsWith('.gif') ||
      normalized.contains('image');
}

/// Normalizes the announcement's media fields (which the backend may
/// represent as plain URL strings or richer attachment objects) into a
/// uniform `{name, url}` shape.
List<Map<String, String>> extractAnnouncementMediaItems(Map<String, dynamic> detail, List<String> keys) {
  final List<Map<String, String>> items = [];

  for (final key in keys) {
    final raw = detail[key];
    if (raw is List) {
      for (final item in raw) {
        if (item is String) {
          items.add({'name': item.split('/').last, 'url': item});
        } else if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final name = map['original_name']?.toString() ??
              map['file_name']?.toString() ??
              map['filename']?.toString() ??
              map['name']?.toString() ??
              map['title']?.toString() ??
              'Lampiran';
          final url = map['file_url']?.toString() ??
              map['secure_url']?.toString() ??
              map['download_url']?.toString() ??
              map['url']?.toString() ??
              map['file_path']?.toString() ??
              map['path']?.toString() ??
              '';
          items.add({'name': name, 'url': url});
        }
      }
    }
  }

  return items;
}
