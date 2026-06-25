import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Shared destructive-action confirmation dialog for admin screens
/// (delete category, delete announcement, delete attachment, bulk delete, etc).
Future<bool> showAdminConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Hapus',
  String cancelText = 'Batal',
  Color confirmColor = AppTheme.danger,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      content: Text(message, style: GoogleFonts.nunito()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText, style: GoogleFonts.nunito()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: confirmColor),
          child: Text(confirmText,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return result == true;
}
