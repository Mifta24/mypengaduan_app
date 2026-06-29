import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

int complaintIdOf(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String complaintStatusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Menunggu';
    case 'processing':
    case 'in_progress':
      return 'Diproses';
    case 'waiting_user_confirmation':
      return 'Konfirmasi';
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
  switch (status) {
    case 'pending':
      return AppTheme.warning;
    case 'in_progress':
    case 'processing':
      return const Color(0xFF0891B2);
    case 'waiting_user_confirmation':
      return const Color(0xFFEA580C);
    case 'resolved':
    case 'completed':
      return AppTheme.primary;
    case 'rejected':
      return AppTheme.danger;
    default:
      return Colors.grey;
  }
}

List<Map<String, dynamic>> extractComplaintAttachments(dynamic complaint) {
  if (complaint is! Map) return const [];

  final raw = complaint['attachments'];
  if (raw is List) {
    return raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  return const [];
}
