import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/app_theme.dart';
import '../category_detail_utils.dart';
import 'category_detail_widgets.dart';

/// Preview tile for the most recent complaint in a category, shown in the
/// "Keluhan Terbaru" section of the category detail screen.
class CategoryComplaintTile extends StatelessWidget {
  final Map<String, dynamic> complaint;

  const CategoryComplaintTile({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final status = complaint['status']?.toString() ?? 'pending';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final id = categoryToInt(complaint['id']);
        if (id > 0) await context.push('/complaint/$id');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              complaint['title']?.toString() ??
                  complaint['description']?.toString() ??
                  '-',
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CategoryDetailBadge(
                  label: categoryComplaintStatusText(status),
                  color: categoryComplaintStatusColor(status),
                  icon: Icons.info_outline_rounded,
                ),
                const Spacer(),
                Text(categoryTimeAgo(complaint['created_at']),
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
