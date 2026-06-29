import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/app_theme.dart';
import '../user_detail_utils.dart';
import 'user_detail_widgets.dart';

/// Preview card for the user's most recent complaint, shown in the
/// "Keluhan Terbaru" section of the user detail screen.
class UserComplaintPreviewCard extends StatelessWidget {
  final Map<String, dynamic> complaint;

  const UserComplaintPreviewCard({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final status = complaint['status']?.toString() ?? 'pending';
    final category = firstString(complaint, ['category_name', 'category', 'category_title'], fallback: 'Tanpa Kategori');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            complaint['title']?.toString() ?? complaint['description']?.toString() ?? '-',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.category_outlined, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(category, style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 12)),
              const Spacer(),
              Text(userTimeAgo(complaint['created_at']), style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          UserDetailBadge(
            label: complaintStatusText(status),
            color: complaintStatusColor(status),
            icon: Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }
}
