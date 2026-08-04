import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../providers/reports_provider.dart';
import '../../../../widgets/admin/admin_info_card.dart';
import '../report_format_utils.dart';
import 'report_metric_tile.dart';

/// "Keluhan" tab: complaint metrics + filterable complaint list.
class ReportComplaintsTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final ReportsProvider provider;
  final String periodFilter;
  final VoidCallback onShowAllData;

  const ReportComplaintsTab({
    super.key,
    required this.items,
    required this.provider,
    required this.periodFilter,
    required this.onShowAllData,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.length;
    final pending = items
        .where((c) =>
            provider.normalizeComplaintStatus(c['status']?.toString() ?? '') ==
            'pending')
        .length;
    final progress = items
        .where((c) =>
            provider.normalizeComplaintStatus(c['status']?.toString() ?? '') ==
            'in_progress')
        .length;
    final resolved = items
        .where((c) =>
            provider.normalizeComplaintStatus(c['status']?.toString() ?? '') ==
            'resolved')
        .length;
    final rejected = items
        .where((c) =>
            provider.normalizeComplaintStatus(c['status']?.toString() ?? '') ==
            'rejected')
        .length;

    final resolutionRate = total == 0 ? 0.0 : (resolved / total * 100);
    final avgResponse = extractAvgResponseHours(provider.overview);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Laporan Keluhan',
              style: GoogleFonts.nunito(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Laporan detail dan analisis keluhan pengguna',
              style: GoogleFonts.nunito(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width < 560 ? 2 : 3;
              final itemWidth =
                  (width - (8 * (crossAxisCount - 1))) / crossAxisCount;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                      width: itemWidth,
                      child: ReportMetricTile(title: 'Total', value: '$total')),
                  SizedBox(
                      width: itemWidth,
                      child: ReportMetricTile(
                          title: 'Pending', value: '$pending')),
                  SizedBox(
                      width: itemWidth,
                      child: ReportMetricTile(
                          title: 'Dalam Proses', value: '$progress')),
                  SizedBox(
                      width: itemWidth,
                      child: ReportMetricTile(
                          title: 'Selesai', value: '$resolved')),
                  SizedBox(
                      width: itemWidth,
                      child: ReportMetricTile(
                          title: 'Ditolak', value: '$rejected')),
                  SizedBox(
                      width: itemWidth,
                      child: ReportMetricTile(
                          title: 'Tingkat Selesai',
                          value: '${resolutionRate.toStringAsFixed(0)}%')),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          ReportMetricTile(
              title: 'Rata-rata Respon',
              value: '${avgResponse.toStringAsFixed(1)} jam',
              fullWidth: true),
          const SizedBox(height: 12),
          Text('Daftar Keluhan',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Total $total keluhan ditemukan'),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    periodFilter == 'all'
                        ? 'Belum ada data keluhan.'
                        : 'Tidak ada keluhan pada periode ini.',
                    style: GoogleFonts.nunito(color: Colors.grey.shade600),
                  ),
                  if (periodFilter != 'all') ...[
                    const SizedBox(height: 8),
                    TextButton(
                        onPressed: onShowAllData,
                        child: const Text('Tampilkan Semua Data')),
                  ],
                ],
              ),
            )
          else
            ...items.map((complaint) =>
                _ComplaintReportCard(complaint: complaint, provider: provider)),
        ],
      ),
    );
  }
}

class _ComplaintReportCard extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final ReportsProvider provider;

  const _ComplaintReportCard({required this.complaint, required this.provider});

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = provider
        .normalizeComplaintStatus(complaint['status']?.toString() ?? '');
    final title = complaint['title']?.toString() ??
        complaint['description']?.toString() ??
        '-';
    final status = reportStatusText(normalizedStatus);
    final statusColor = reportStatusColor(normalizedStatus);
    final userName = provider.complaintUserName(complaint);
    final category = provider.complaintCategoryName(complaint);
    final location = provider.firstString(
        complaint, ['address', 'location', 'full_address'],
        fallback: '-');
    final priority =
        provider.firstString(complaint, ['priority'], fallback: 'Sedang');
    final created = provider.parseDate(complaint['created_at']);

    return AdminInfoCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderColor: Colors.grey.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.nunito(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(userName,
                            style: GoogleFonts.nunito(
                                color: Colors.grey[700], fontSize: 13)),
                        const SizedBox(width: 12),
                        Icon(Icons.category, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(category,
                            style: GoogleFonts.nunito(
                                color: Colors.grey[700], fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: GoogleFonts.nunito(
                                color: Colors.grey[700], fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          created == null
                              ? '-'
                              : DateFormat('dd/MM/yyyy HH:mm').format(created),
                          style: GoogleFonts.nunito(
                              color: Colors.grey[600], fontSize: 12),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Prioritas: $priority',
                            style: GoogleFonts.nunito(
                                color: Colors.blue[700], fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () async {
                final id = complaint['id'];
                if (id == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Detail keluhan tidak tersedia')),
                  );
                  return;
                }
                await context.push('/complaint/$id');
              },
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child:
                  Text('Lihat Detail', style: GoogleFonts.nunito(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
