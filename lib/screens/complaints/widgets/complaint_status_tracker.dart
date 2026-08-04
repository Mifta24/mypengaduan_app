import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/complaint_model.dart';
import '../../../theme/app_theme.dart';
import '../complaint_detail_utils.dart';

class ComplaintStatusTracker extends StatelessWidget {
  final Complaint complaint;
  const ComplaintStatusTracker({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    const steps = [
      ('Diterima', 'Keluhan Anda telah diterima.'),
      ('Diverifikasi', 'Keluhan Anda sedang diverifikasi.'),
      ('Dalam Proses', 'Keluhan Anda sedang dalam proses penanganan.'),
      ('Selesai', 'Keluhan Anda telah selesai ditangani.'),
    ];
    final times = [c.createdAt, c.updatedAt, c.updatedAt, c.updatedAt];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: complaintCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Penanganan',
              style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) {
            final state = complaintStepState(i, c.status);
            return _TrackingStep(
              title: steps[i].$1,
              desc: steps[i].$2,
              time: state >= 1 ? times[i] : null,
              state: state,
              isLast: i == steps.length - 1,
            );
          }),
          if (c.status == 'rejected') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined,
                      color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pengaduan ini ditolak dan tidak dapat diproses.',
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: const Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackingStep extends StatelessWidget {
  final String title;
  final String desc;
  final DateTime? time;
  final int state; // 0=pending, 1=done, 2=active, -1=rejected-inactive
  final bool isLast;

  const _TrackingStep({
    required this.title,
    required this.desc,
    this.time,
    required this.state,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final Color circleColor;
    final Color lineColor;
    final Widget circleChild;

    if (state == 1) {
      circleColor = AppTheme.primary;
      lineColor = AppTheme.primary;
      circleChild =
          const Icon(Icons.check_rounded, size: 14, color: Colors.white);
    } else if (state == 2) {
      circleColor = const Color(0xFFEA580C);
      lineColor = AppTheme.border;
      circleChild = Container(
        width: 8,
        height: 8,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      );
    } else {
      circleColor = Colors.grey.shade300;
      lineColor = AppTheme.border;
      circleChild = Container(
        width: 8,
        height: 8,
        decoration:
            BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration:
                    BoxDecoration(color: circleColor, shape: BoxShape.circle),
                child: Center(child: circleChild),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 44,
                  color: lineColor,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: state == 0
                            ? Colors.grey.shade400
                            : AppTheme.textPrimary)),
                if (time != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(time!),
                    style: GoogleFonts.nunito(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
                const SizedBox(height: 3),
                Text(desc,
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: state == 0
                            ? Colors.grey.shade400
                            : AppTheme.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
