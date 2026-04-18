import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.6)),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
