import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/app_theme.dart';

/// Small display atoms reused across the admin category detail screen.

class CategoryDetailBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const CategoryDetailBadge({super.key, required this.label, required this.color, required this.icon});

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

class CategoryDetailSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final IconData? icon;

  const CategoryDetailSectionHeader({super.key, required this.title, this.action, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primary),
          ),
          const SizedBox(width: 8),
        ],
        Text(title, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

class CategoryDetailStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const CategoryDetailStatCard({super.key, required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(title, style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class CategoryDetailEmptyTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const CategoryDetailEmptyTile({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 32, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class CategoryDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const CategoryDetailRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
              Text(value, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
