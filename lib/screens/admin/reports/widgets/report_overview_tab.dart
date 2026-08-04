import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/app_theme.dart';
import '../report_format_utils.dart';
import 'report_pie_chart_painter.dart';

/// "Ringkasan" tab: summary cards, status pie chart and per-category bar chart.
class ReportOverviewTab extends StatelessWidget {
  final Map<String, dynamic>? overview;
  final Map<String, dynamic>? statistics;

  const ReportOverviewTab(
      {super.key, required this.overview, required this.statistics});

  @override
  Widget build(BuildContext context) {
    final overviewData = (overview?['data'] as Map<String, dynamic>?) ?? {};
    final stats = (overviewData['statistics'] as Map<String, dynamic>?) ?? {};

    final totalComplaints =
        _toInt(stats['total_complaints'] ?? overviewData['total_complaints']);
    final byStatus = ((statistics?['data']
            as Map<String, dynamic>?)?['by_status'] as Map<String, dynamic>?) ??
        ((overviewData['complaints_by_status'] as Map<String, dynamic>?) ?? {});
    final resolved = _toInt(byStatus['resolved'] ?? byStatus['completed']);
    final pending = _toInt(byStatus['pending']);
    final inProgress =
        _toInt(byStatus['in_progress'] ?? byStatus['processing']);
    final rejected = _toInt(byStatus['rejected']);
    final avgResponse = extractAvgResponseHours(overview);

    final byCategory = ((statistics?['data']
            as Map<String, dynamic>?)?['by_category'] as List?) ??
        [];
    final topCategories = byCategory
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .take(5)
        .toList();
    final maxCat = topCategories.isEmpty
        ? 1
        : topCategories
            .map((c) => _toInt(c['total'] ?? c['count']))
            .reduce(math.max);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _SummaryCard(
                  label: 'Total Pengaduan',
                  value: '$totalComplaints',
                  color: AppTheme.primary,
                  icon: Icons.assignment_rounded),
              _SummaryCard(
                  label: 'Selesai',
                  value: '$resolved',
                  color: const Color(0xFF059669),
                  icon: Icons.check_circle_rounded),
              _SummaryCard(
                  label: 'Ditolak',
                  value: '$rejected',
                  color: const Color(0xFFDC2626),
                  icon: Icons.cancel_rounded),
              _SummaryCard(
                  label: 'Rata-rata Waktu',
                  value: '${avgResponse.toStringAsFixed(1)} hari',
                  color: const Color(0xFF0891B2),
                  icon: Icons.timer_rounded),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Distribusi Status',
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CustomPaint(
                        painter: ReportPieChartPainter(
                          segments: [
                            (resolved.toDouble(), AppTheme.primary),
                            (inProgress.toDouble(), const Color(0xFF0891B2)),
                            (pending.toDouble(), const Color(0xFFD97706)),
                            (rejected.toDouble(), const Color(0xFFDC2626)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LegendItem(
                              label: 'Selesai',
                              count: resolved,
                              color: AppTheme.primary,
                              total: totalComplaints),
                          _LegendItem(
                              label: 'Diproses',
                              count: inProgress,
                              color: const Color(0xFF0891B2),
                              total: totalComplaints),
                          _LegendItem(
                              label: 'Menunggu',
                              count: pending,
                              color: const Color(0xFFD97706),
                              total: totalComplaints),
                          _LegendItem(
                              label: 'Ditolak',
                              count: rejected,
                              color: const Color(0xFFDC2626),
                              total: totalComplaints),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (topCategories.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pengaduan per Kategori',
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 14),
                  ...topCategories.map((cat) {
                    final name = cat['category']?.toString() ??
                        cat['category_name']?.toString() ??
                        'Kategori';
                    final count = _toInt(cat['total'] ?? cat['count']);
                    final ratio = maxCat == 0 ? 0.0 : count / maxCat;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(name,
                                style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 12,
                                backgroundColor: Colors.grey.shade100,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppTheme.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$count',
                              style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 22, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final int total;

  const _LegendItem(
      {required this.label,
      required this.count,
      required this.color,
      required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total * 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: AppTheme.textPrimary))),
          Text('$count (${pct.toStringAsFixed(1)}%)',
              style: GoogleFonts.nunito(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
