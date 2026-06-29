import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/app_theme.dart';

/// Small display atoms reused across the admin announcement detail screen.

class AnnouncementDetailBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const AnnouncementDetailBadge({super.key, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class AnnouncementSectionTitle extends StatelessWidget {
  final String title;
  const AnnouncementSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary));
  }
}

class AnnouncementContentBlock extends StatelessWidget {
  final String content;
  final bool isItalic;

  const AnnouncementContentBlock({super.key, required this.content, this.isItalic = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        content,
        style: GoogleFonts.nunito(
          fontSize: 14,
          color: AppTheme.textPrimary.withValues(alpha: 0.8),
          height: 1.6,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }
}

class AnnouncementDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const AnnouncementDetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
