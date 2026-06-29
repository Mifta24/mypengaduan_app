import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../providers/reports_provider.dart';
import '../../../../widgets/admin/admin_info_card.dart';
import '../report_format_utils.dart';
import 'report_metric_tile.dart';

/// "Pengguna" tab: user metrics + filterable user list.
class ReportUsersTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final ReportsProvider provider;
  final String periodFilter;
  final VoidCallback onShowAllData;

  const ReportUsersTab({
    super.key,
    required this.items,
    required this.provider,
    required this.periodFilter,
    required this.onShowAllData,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.length;
    final active = items.where((u) => provider.toBool(u['is_active'])).length;
    final inactive = total - active;
    final monthCount = items.where((u) {
      final created = provider.parseDate(u['created_at']);
      if (created == null) return false;
      final now = DateTime.now();
      return created.year == now.year && created.month == now.month;
    }).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Laporan Pengguna', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Laporan detail dan analisis pengguna sistem', style: GoogleFonts.nunito(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width < 560 ? 2 : (width < 900 ? 3 : 4);
              final itemWidth = (width - (8 * (crossAxisCount - 1))) / crossAxisCount;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(width: itemWidth, child: ReportMetricTile(title: 'Total Pengguna', value: '$total')),
                  SizedBox(width: itemWidth, child: ReportMetricTile(title: 'Aktif', value: '$active')),
                  SizedBox(width: itemWidth, child: ReportMetricTile(title: 'Tidak Aktif', value: '$inactive')),
                  SizedBox(width: itemWidth, child: ReportMetricTile(title: 'Bulan Ini', value: '$monthCount')),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text('Daftar Pengguna', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Total $total pengguna ditemukan'),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    periodFilter == 'all' ? 'Belum ada data pengguna.' : 'Tidak ada pengguna terdaftar pada periode ini.',
                    style: GoogleFonts.nunito(color: Colors.grey.shade600),
                  ),
                  if (periodFilter != 'all') ...[
                    const SizedBox(height: 8),
                    TextButton(onPressed: onShowAllData, child: const Text('Tampilkan Semua Data')),
                  ],
                ],
              ),
            )
          else
            ...items.map((user) => _UserReportCard(user: user, provider: provider)),
        ],
      ),
    );
  }
}

class _UserReportCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final ReportsProvider provider;

  const _UserReportCard({required this.user, required this.provider});

  @override
  Widget build(BuildContext context) {
    final name = user['name']?.toString() ?? '-';
    final email = user['email']?.toString() ?? '-';
    final phone = user['phone']?.toString() ?? '';
    final isActive = provider.toBool(user['is_active']);
    final complaintsCount = provider.toInt(user['complaints_count']);
    final created = provider.parseDate(user['created_at']);
    final emailVerified = provider.toBool(user['is_email_verified']) || user['email_verified_at'] != null;
    final initials = reportInitials(name);

    return AdminInfoCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderColor: Colors.grey.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.withValues(alpha: 0.15),
                child: Text(initials, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.blue)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(email, style: GoogleFonts.nunito(color: Colors.grey[600], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Aktif' : 'Tidak Aktif',
                  style: GoogleFonts.nunito(color: isActive ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (phone.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(phone, style: GoogleFonts.nunito(color: Colors.grey[700], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Bergabung: ${created == null ? '-' : DateFormat('dd/MM/yyyy').format(created)}',
                style: GoogleFonts.nunito(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(emailVerified ? Icons.verified : Icons.warning_amber, size: 14, color: emailVerified ? Colors.blue : Colors.orange),
              const SizedBox(width: 6),
              Text(
                emailVerified ? 'Email terverifikasi' : 'Email belum terverifikasi',
                style: GoogleFonts.nunito(color: emailVerified ? Colors.blue[700] : Colors.orange[700], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description, size: 14, color: Colors.grey[700]),
                    const SizedBox(width: 6),
                    Text(
                      '$complaintsCount keluhan',
                      style: GoogleFonts.nunito(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => _showUserDetailDialog(context, user),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 32),
              ),
              child: Text('Detail', style: GoogleFonts.nunito(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetailDialog(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['name']?.toString() ?? 'Detail Pengguna'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${user['email'] ?? '-'}'),
              Text('Telepon: ${user['phone'] ?? '-'}'),
              Text('Role: ${user['role'] ?? 'user'}'),
              Text('Status: ${provider.toBool(user['is_active']) ? 'Aktif' : 'Tidak Aktif'}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }
}
