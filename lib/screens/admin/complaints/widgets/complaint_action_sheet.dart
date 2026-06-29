import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/app_theme.dart';
import '../complaint_status_utils.dart';

/// Long-press bottom sheet with the quick actions for a single complaint.
void showComplaintActionSheet(
  BuildContext context,
  dynamic item, {
  required VoidCallback onResolve,
  required VoidCallback onMarkInProgress,
  required VoidCallback onReject,
  required VoidCallback onManageAttachments,
  required VoidCallback onMoveToTrash,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item['title']?.toString() ?? 'Aksi Pengaduan',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                onResolve();
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text('Selesaikan', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                onMarkInProgress();
              },
              icon: const Icon(Icons.autorenew, size: 18),
              label: Text('Tandai Diproses', style: GoogleFonts.nunito()),
              style: OutlinedButton.styleFrom(
                foregroundColor: complaintStatusColor('in_progress'),
                side: BorderSide(color: complaintStatusColor('in_progress')),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                onReject();
              },
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: Text('Tolak', style: GoogleFonts.nunito()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                onManageAttachments();
              },
              icon: const Icon(Icons.attach_file, size: 18),
              label: Text('Hapus Attachment', style: GoogleFonts.nunito()),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                onMoveToTrash();
              },
              icon: const Icon(Icons.delete_sweep, size: 18),
              label: Text('Pindah Trash', style: GoogleFonts.nunito(color: AppTheme.danger)),
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    ),
  );
}
