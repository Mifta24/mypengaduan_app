import 'package:flutter/material.dart';

/// Shared formatting helpers for the admin reports screens.
String reportStatusText(String normalizedStatus) {
  switch (normalizedStatus) {
    case 'pending':
      return 'Pending';
    case 'in_progress':
      return 'Dalam Proses';
    case 'resolved':
      return 'Selesai';
    case 'rejected':
      return 'Ditolak';
    default:
      return normalizedStatus;
  }
}

Color reportStatusColor(String normalizedStatus) {
  switch (normalizedStatus) {
    case 'pending':
      return Colors.orange;
    case 'in_progress':
      return Colors.blue;
    case 'resolved':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

double extractAvgResponseHours(Map<String, dynamic>? overview) {
  final stats = (overview?['data'] as Map<String, dynamic>?) ?? {};

  final raw = stats['avg_response_time'] ?? stats['average_response_time'] ?? stats['avg_response_hours'];
  if (raw == null) return 0;

  if (raw is num) return raw.toDouble();

  final text = raw.toString().toLowerCase();
  final number = double.tryParse(RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(text)?.group(1) ?? '0') ?? 0;

  if (text.contains('day') || text.contains('hari')) {
    return number * 24;
  }

  return number;
}

String reportInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'US';
  if (parts.length == 1) {
    final p = parts.first;
    return p.length >= 2 ? p.substring(0, 2).toUpperCase() : p.substring(0, 1).toUpperCase();
  }
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}
