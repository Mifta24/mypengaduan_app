import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/complaint_model.dart';
import '../../../theme/app_theme.dart';
import '../complaint_detail_utils.dart';

class ComplaintResponseThread extends StatelessWidget {
  final Complaint complaint;
  const ComplaintResponseThread({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final thread = [...complaint.responses]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: complaintCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tanggapan Petugas', style: complaintSectionTitle(context)),
          const SizedBox(height: 12),
          ...thread.map((item) {
            final isAdmin = item.isAdmin;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAdmin
                    ? AppTheme.primary.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAdmin
                      ? AppTheme.primary.withValues(alpha: 0.15)
                      : AppTheme.border,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isAdmin ? AppTheme.primary : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        item.userName.isNotEmpty
                            ? item.userName[0].toUpperCase()
                            : 'A',
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(isAdmin ? 'Admin' : item.userName,
                                style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary)),
                            const Spacer(),
                            Text(
                              DateFormat('dd MMM, HH:mm', 'id_ID')
                                  .format(item.createdAt),
                              style: GoogleFonts.nunito(
                                  fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(item.message,
                            style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                                height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class ComplaintLegacyResponse extends StatelessWidget {
  final String response;
  const ComplaintLegacyResponse({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
                color: AppTheme.primary, shape: BoxShape.circle),
            child: const Center(
              child: Icon(Icons.admin_panel_settings,
                  size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin',
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 5),
                Text(response,
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ComplaintResponseForm extends StatelessWidget {
  final TextEditingController controller;
  final bool isAdmin;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const ComplaintResponseForm({
    super.key,
    required this.controller,
    required this.isAdmin,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: complaintCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isAdmin ? 'Berikan Tanggapan' : 'Beri Umpan Balik',
              style: complaintSectionTitle(context)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 4,
            style:
                GoogleFonts.nunito(fontSize: 14, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: isAdmin
                  ? 'Tulis tanggapan Anda untuk pengaduan ini...'
                  : 'Tulis umpan balik atau pertanyaan Anda...',
              hintStyle:
                  GoogleFonts.nunito(fontSize: 14, color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppTheme.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(isSubmitting ? 'Mengirim...' : 'Kirim',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ComplaintConfirmationCard extends StatelessWidget {
  final VoidCallback onConfirm;
  const ComplaintConfirmationCard({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user,
                  size: 20, color: Color(0xFFEA580C)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Tindakan Anda Dibutuhkan',
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF9A3412))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pengaduan telah ditangani admin. Konfirmasi jika masalah benar-benar selesai.',
            style: GoogleFonts.nunito(
                fontSize: 13, color: const Color(0xFF9A3412), height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text('Konfirmasi Sekarang',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ComplaintReporterCard extends StatelessWidget {
  final Map<String, dynamic> reporter;
  final int? userId;

  const ComplaintReporterCard({
    super.key,
    required this.reporter,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final name = (reporter['name'] ?? reporter['full_name'])?.toString();
    final email = reporter['email']?.toString();
    final phone = reporter['phone']?.toString();
    final nik = (reporter['nik'] ?? reporter['national_id'])?.toString();

    return Container(
      decoration: complaintCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Informasi Pelapor',
                style: complaintSectionTitle(context)),
          ),
          Divider(height: 1, color: AppTheme.border),
          _InfoRow(
              Icons.person_outline, 'Nama', name ?? 'ID #${userId ?? '-'}'),
          if (email?.isNotEmpty == true)
            _InfoRow(Icons.email_outlined, 'Email', email!),
          if (phone?.isNotEmpty == true)
            _InfoRow(Icons.phone_outlined, 'Telepon', phone!),
          if (nik?.isNotEmpty == true) _InfoRow(Icons.credit_card, 'NIK', nik!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.nunito(
                        fontSize: 11, color: AppTheme.textSecondary)),
                Text(value,
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
