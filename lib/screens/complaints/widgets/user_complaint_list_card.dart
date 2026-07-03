import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/complaint_model.dart';
import '../../../theme/app_theme.dart';

({Color color, Color bg, String label, IconData icon}) complaintListStatusInfo(String s) {
  switch (s) {
    case 'pending':
      return (color: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7),
          label: 'Menunggu', icon: Icons.schedule_rounded);
    case 'in_progress':
      return (color: const Color(0xFF0891B2), bg: const Color(0xFFDBEAFE),
          label: 'Diproses', icon: Icons.sync_rounded);
    case 'waiting_user_confirmation':
      return (color: const Color(0xFFEA580C), bg: const Color(0xFFFFF7ED),
          label: 'Konfirmasi', icon: Icons.hourglass_top_rounded);
    case 'resolved':
      return (color: AppTheme.primary, bg: const Color(0xFFD1FAE5),
          label: 'Selesai', icon: Icons.check_circle_rounded);
    case 'rejected':
      return (color: const Color(0xFFDC2626), bg: const Color(0xFFFEE2E2),
          label: 'Ditolak', icon: Icons.cancel_rounded);
    default:
      return (color: Colors.grey, bg: Colors.grey.shade100,
          label: s, icon: Icons.info_rounded);
  }
}

class UserComplaintWaitingBanner extends StatelessWidget {
  final List<Complaint> waitingComplaints;
  final void Function(Complaint complaint) onOpen;

  const UserComplaintWaitingBanner({
    super.key,
    required this.waitingComplaints,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final sortedWaiting = [...waitingComplaints]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final highlighted = sortedWaiting.first;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.priority_high_rounded,
                color: Color(0xFFEA580C), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Perlu Konfirmasi Anda',
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF9A3412))),
                const SizedBox(height: 2),
                Text(
                  '${waitingComplaints.length} pengaduan menunggu konfirmasi selesai',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF9A3412),
                      height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () => onOpen(highlighted),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: Text('Buka',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class UserComplaintListCard extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onConfirm;

  const UserComplaintListCard({
    super.key,
    required this.complaint,
    required this.onTap,
    this.onEdit,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final si = complaintListStatusInfo(complaint.status);
    final showActions = complaint.status == 'pending' ||
        complaint.status == 'waiting_user_confirmation';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: si.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${complaint.id.toString().padLeft(4, '0')}',
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(info: si),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 11, color: Colors.grey.shade400),
                              const SizedBox(width: 3),
                              Text(
                                DateFormat('dd/MM/yy').format(complaint.reportDate),
                                style: GoogleFonts.nunito(
                                    fontSize: 11, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        complaint.title,
                        style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        complaint.description,
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (complaint.category != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sell_outlined,
                                      size: 11, color: AppTheme.primary),
                                  const SizedBox(width: 3),
                                  Text(complaint.category!.name,
                                      style: GoogleFonts.nunito(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 12, color: Colors.grey.shade400),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    complaint.location,
                                    style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        color: Colors.grey.shade400),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (showActions) ...[
                        const SizedBox(height: 10),
                        Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (complaint.status == 'pending' && onEdit != null)
                              TextButton.icon(
                                onPressed: onEdit,
                                icon: const Icon(Icons.edit_rounded, size: 15),
                                label: Text('Edit',
                                    style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            if (complaint.status == 'waiting_user_confirmation' &&
                                onConfirm != null)
                              FilledButton.icon(
                                onPressed: onConfirm,
                                icon: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 15),
                                label: Text('Konfirmasi Selesai',
                                    style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFEA580C),
                                  foregroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ({Color color, Color bg, String label, IconData icon}) info;
  const _StatusBadge({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: info.bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: 11, color: info.color),
          const SizedBox(width: 3),
          Text(info.label,
              style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: info.color)),
        ],
      ),
    );
  }
}
