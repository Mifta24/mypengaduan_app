import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

String announcementPriorityText(String priority) {
  switch (priority.toLowerCase()) {
    case 'urgent':
      return 'Mendesak';
    case 'high':
      return 'Tinggi';
    case 'medium':
      return 'Sedang';
    case 'low':
      return 'Rendah';
    default:
      return 'Sedang';
  }
}

Color announcementPriorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'urgent':
      return const Color(0xFFDC2626);
    case 'high':
      return const Color(0xFFEA580C);
    case 'medium':
      return const Color(0xFF0891B2);
    case 'low':
      return AppTheme.primary;
    default:
      return AppTheme.primary;
  }
}

List<Color> announcementPriorityGradient(String priority) {
  switch (priority.toLowerCase()) {
    case 'urgent':
      return [const Color(0xFFDC2626), const Color(0xFFB91C1C)];
    case 'high':
      return [const Color(0xFFEA580C), const Color(0xFFC2410C)];
    case 'medium':
      return [const Color(0xFF0891B2), const Color(0xFF15803D)];
    case 'low':
      return [AppTheme.primary, const Color(0xFF15803D)];
    default:
      return [AppTheme.primary, AppTheme.secondary];
  }
}

bool isAnnouncementImageUrl(String url) {
  final lower = url.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.bmp');
}
