import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/app_theme.dart';
import '../complaint_status_utils.dart';

/// Single row card in the admin complaints list.
class ComplaintListCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ComplaintListCard(
      {super.key,
      required this.item,
      required this.onTap,
      required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString().toLowerCase() ?? 'pending';
    final statusColor = complaintStatusColor(status);
    final statusLabel = complaintStatusLabel(status);

    final userName =
        item['user'] is Map ? (item['user']['name']?.toString() ?? 'P') : 'P';
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'P';

    final title = item['title']?.toString() ?? 'Tanpa Judul';
    final category = item['category'] is Map
        ? item['category']['name']?.toString()
        : item['category_name']?.toString();
    final location =
        item['address']?.toString() ?? item['location']?.toString() ?? '';
    final createdAt = item['created_at']?.toString() ?? '';
    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateStr =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        dateStr =
            createdAt.length > 10 ? createdAt.substring(0, 10) : createdAt;
      }
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.15)),
                alignment: Alignment.center,
                child: Text(
                  firstLetter,
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: statusColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category != null && category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (location.isNotEmpty) location,
                        if (dateStr.isNotEmpty) dateStr
                      ].join(' • '),
                      style: GoogleFonts.nunito(
                          fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right,
                      size: 16, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
