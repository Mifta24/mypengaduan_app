import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import 'category_detail_utils.dart';

/// All complaints for a single category, grouped into tabs by status.
class CategoryComplaintsScreen extends StatelessWidget {
  final String categoryName;
  final List<Map<String, dynamic>> complaints;

  const CategoryComplaintsScreen({
    super.key,
    required this.categoryName,
    required this.complaints,
  });

  @override
  Widget build(BuildContext context) {
    final pending = complaints.where((c) {
      final s = c['status']?.toString().toLowerCase() ?? '';
      return s == 'pending';
    }).toList();
    final inProgress = complaints.where((c) {
      final s = c['status']?.toString().toLowerCase() ?? '';
      return s == 'processing' || s == 'in_progress';
    }).toList();
    final resolved = complaints.where((c) {
      final s = c['status']?.toString().toLowerCase() ?? '';
      return s == 'resolved' || s == 'completed';
    }).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: Text('Keluhan — $categoryName', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          bottom: TabBar(
            isScrollable: true,
            labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.nunito(fontSize: 13),
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: [
              Tab(text: 'Semua (${complaints.length})'),
              Tab(text: 'Pending (${pending.length})'),
              Tab(text: 'Proses (${inProgress.length})'),
              Tab(text: 'Selesai (${resolved.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ComplaintStatusList(items: complaints),
            _ComplaintStatusList(items: pending),
            _ComplaintStatusList(items: inProgress),
            _ComplaintStatusList(items: resolved),
          ],
        ),
      ),
    );
  }
}

class _ComplaintStatusList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _ComplaintStatusList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Belum ada keluhan', style: GoogleFonts.nunito(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final complaint = items[i];
        final status = complaint['status']?.toString() ?? '-';
        final color = categoryComplaintStatusColor(status);
        final label = categoryComplaintStatusText(status);

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final id = complaint['id'];
            if (id != null) await ctx.push('/complaint/$id');
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint['title']?.toString() ?? complaint['description']?.toString() ?? '-',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(label, style: GoogleFonts.nunito(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    Text(
                      complaint['created_at'] != null
                          ? DateFormat('d MMM y').format(DateTime.parse(complaint['created_at'].toString()).toLocal())
                          : '-',
                      style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
