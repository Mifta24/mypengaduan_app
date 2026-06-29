import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import 'user_detail_utils.dart';

/// Args for [AdminUserComplaintsScreen]. [fetchComplaints] stays bound to the
/// caller's [AdminService] instance and id filtering, kept as a callback so
/// no fetch/business logic is duplicated here.
class AdminUserComplaintsArgs {
  final String userName;
  final Future<List<Map<String, dynamic>>> Function() fetchComplaints;

  const AdminUserComplaintsArgs({
    required this.userName,
    required this.fetchComplaints,
  });
}

class AdminUserComplaintsScreen extends StatelessWidget {
  final AdminUserComplaintsArgs args;

  const AdminUserComplaintsScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Semua Keluhan - ${args.userName}')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: args.fetchComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final complaints = snapshot.data ?? [];
          if (complaints.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Pengguna ini belum memiliki keluhan.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _ComplaintTile(complaint: complaints[index]),
          );
        },
      ),
    );
  }
}

class _ComplaintTile extends StatelessWidget {
  final Map<String, dynamic> complaint;
  const _ComplaintTile({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final status = complaint['status']?.toString() ?? 'pending';
    final id = toIntValue(complaint['id']);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: id <= 0 ? null : () => context.push('/complaint/$id'),
      child: Container(
        width: double.infinity,
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
                    color: complaintStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    complaintStatusText(status),
                    style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: complaintStatusColor(status)),
                  ),
                ),
                const Spacer(),
                Text(
                  firstString(complaint, ['category_name', 'category', 'category_title'], fallback: 'Tanpa Kategori'),
                  style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
