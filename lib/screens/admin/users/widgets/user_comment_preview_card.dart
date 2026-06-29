import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/app_theme.dart';
import '../user_detail_utils.dart';

/// Preview card for the user's most recent comment, shown in the
/// "Komentar Terbaru" section of the user detail screen.
class UserCommentPreviewCard extends StatelessWidget {
  final Map<String, dynamic> comment;

  const UserCommentPreviewCard({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final content = firstString(comment, ['content', 'comment', 'message'], fallback: '-');
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
          Row(
            children: [
              Icon(Icons.format_quote_rounded, color: AppTheme.primary.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Expanded(child: Text(content, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
            ],
          ),
          const SizedBox(height: 12),
          Text(userTimeAgo(comment['created_at']), style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
