import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/complaint_model.dart';
import '../../../theme/app_theme.dart';
import '../complaint_detail_utils.dart';

class ComplaintIdCard extends StatelessWidget {
  final Complaint complaint;
  final ComplaintStatusInfo statusInfo;

  const ComplaintIdCard(
      {super.key, required this.complaint, required this.statusInfo});

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final si = statusInfo;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: complaintCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Keluhan #${c.id.toString().padLeft(4, '0')}',
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (c.isPublic ? AppTheme.primary : AppTheme.textSecondary)
                          .withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      c.isPublic
                          ? Icons.public_rounded
                          : Icons.lock_outline_rounded,
                      size: 12,
                      color: c.isPublic
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      c.visibilityText,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.isPublic
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: si.bg, borderRadius: BorderRadius.circular(20)),
                child: Text(si.label,
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: si.color)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Dibuat pada ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(c.createdAt)} WIB',
            style:
                GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class ComplaintMainCard extends StatelessWidget {
  final Complaint complaint;
  const ComplaintMainCard({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: complaintCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (c.category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sell_outlined, size: 13, color: AppTheme.primary),
                  const SizedBox(width: 5),
                  Text(c.category!.name,
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(c.title,
              style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.3)),
          const SizedBox(height: 12),
          Divider(color: AppTheme.border),
          const SizedBox(height: 8),
          Text('Deskripsi',
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Text(c.description,
              style: GoogleFonts.nunito(
                  fontSize: 14, color: AppTheme.textPrimary, height: 1.6)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 5),
              Text(
                'Tanggal kejadian: ${DateFormat('dd MMM yyyy', 'id_ID').format(c.reportDate)}',
                style: GoogleFonts.nunito(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ComplaintLocationCard extends StatelessWidget {
  final String location;
  const ComplaintLocationCard({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: complaintCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lokasi Kejadian',
              style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_rounded,
                  size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(location,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
