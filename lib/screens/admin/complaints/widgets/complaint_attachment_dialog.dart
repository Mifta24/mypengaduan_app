import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/admin/admin_confirm_dialog.dart';
import '../complaint_status_utils.dart';

/// Shows the "Hapus Attachment" dialog for a complaint. [onDeleteAttachment]
/// performs the actual API call and should rethrow on failure so the item
/// stays in the visible list.
Future<void> showComplaintAttachmentDialog(
  BuildContext context,
  dynamic complaint, {
  required Future<void> Function(int attachmentId) onDeleteAttachment,
}) async {
  final attachments = extractComplaintAttachments(complaint);
  if (attachments.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak ada attachment pada pengaduan ini')),
    );
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocalState) => AlertDialog(
        title: const Text('Hapus Attachment'),
        content: SizedBox(
          width: 420,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: attachments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = attachments[index];
              final id = complaintIdOf(item['id']);
              final name = item['name']?.toString() ??
                  item['filename']?.toString() ??
                  item['file_name']?.toString() ??
                  'Attachment #$id';

              return Row(
                children: [
                  Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  TextButton(
                    onPressed: id <= 0
                        ? null
                        : () async {
                            final confirmed = await showAdminConfirmDialog(
                              context,
                              title: 'Hapus Attachment',
                              message: 'Hapus "$name" dari pengaduan ini?',
                            );
                            if (!confirmed) return;
                            try {
                              await onDeleteAttachment(id);
                              setLocalState(() => attachments.removeAt(index));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Attachment berhasil dihapus'),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal hapus attachment: $e'), backgroundColor: AppTheme.danger),
                                );
                              }
                            }
                          },
                    child: const Text('Hapus', style: TextStyle(color: AppTheme.danger)),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Tutup')),
        ],
      ),
    ),
  );
}
