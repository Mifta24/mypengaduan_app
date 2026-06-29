import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import 'user_detail_utils.dart';
import 'widgets/user_complaint_preview_card.dart';
import 'widgets/user_comment_preview_card.dart';
import 'widgets/user_detail_widgets.dart';
import 'widgets/user_ktp_card.dart';

/// Bundles the user payload plus the callbacks that perform the actual
/// mutations (verify, toggle status, reset password, delete, edit, ...).
/// The callbacks stay owned by [AdminUsersTab]'s state so this screen never
/// duplicates that business logic — it only renders and delegates.
class AdminUserDetailArgs {
  final dynamic user;
  final Future<Map<String, dynamic>> Function(dynamic user) fetchDetail;
  final Future<void> Function(Map<String, dynamic> detail) onEditUser;
  final Future<void> Function(Map<String, dynamic> detail,
      {required bool shouldVerify}) onToggleVerification;
  final Future<void> Function(Map<String, dynamic> detail,
      {required bool shouldVerify}) onToggleEmailVerification;
  final Future<void> Function(Map<String, dynamic> detail) onToggleStatus;
  final Future<void> Function(int id, {String? userName}) onResetPassword;
  final Future<void> Function(Map<String, dynamic> detail) onDelete;
  final Future<void> Function(Map<String, dynamic> detail) onShowAllComplaints;

  const AdminUserDetailArgs({
    required this.user,
    required this.fetchDetail,
    required this.onEditUser,
    required this.onToggleVerification,
    required this.onToggleEmailVerification,
    required this.onToggleStatus,
    required this.onResetPassword,
    required this.onDelete,
    required this.onShowAllComplaints,
  });
}

class AdminUserDetailScreen extends StatelessWidget {
  final AdminUserDetailArgs args;

  const AdminUserDetailScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengguna')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: args.fetchDetail(args.user),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final detail = snapshot.data ?? Map<String, dynamic>.from(args.user as Map);
          return _UserDetailBody(detail: detail, args: args);
        },
      ),
    );
  }
}

class _UserDetailBody extends StatelessWidget {
  final Map<String, dynamic> detail;
  final AdminUserDetailArgs args;

  const _UserDetailBody({required this.detail, required this.args});

  @override
  Widget build(BuildContext context) {
    final id = toIntValue(detail['id']);
    final role = detail['role']?.toString() ?? 'user';
    final roleColor = role == 'admin' ? Colors.indigo : Colors.teal;
    final isVerified = toBoolValue(detail['is_user_verified']) || toBoolValue(detail['is_verified']);
    final isEmailVerified = toBoolValue(detail['is_email_verified']) || detail['email_verified_at'] != null;
    final isActive = detail['is_active'] == null ? true : toBoolValue(detail['is_active']);

    final totalComplaints = firstInt(detail, [
      'complaints_count',
      'total_complaints',
      'total_keluhan',
      'resolved_complaints',
      'total_reports',
    ]);
    final resolvedComplaintsRaw = firstInt(detail, [
      'resolved_complaints_count',
      'resolved_complaints',
      'resolved_count',
      'completed_complaints_count',
      'completed_complaints',
      'completed_count',
      'resolved',
      'completed',
      'keluhan_selesai',
    ]);

    final resolvedComplaints = resolvedComplaintsRaw > 0
        ? resolvedComplaintsRaw
        : countComplaintsByStatus(detail, const {'resolved', 'completed'});

    final pendingComplaintsRaw = firstInt(detail, [
      'pending_complaints_count',
      'pending_count',
      'in_progress_count',
      'pending',
      'in_progress',
      'keluhan_pending',
    ]);

    final pendingComplaints = pendingComplaintsRaw > 0
        ? pendingComplaintsRaw
        : countComplaintsByStatus(detail, const {'pending', 'in_progress', 'processing'});

    final totalComplaintsFinal = totalComplaints > 0 ? totalComplaints : extractComplaintList(detail).length;
    final totalComments = firstInt(detail, ['comments_count', 'total_comments', 'komentar_count']);

    final latestComplaint = firstMap(detail, ['latest_complaint', 'recent_complaint']) ??
        firstMapFromList(detail, ['latest_complaints', 'recent_complaints', 'complaints']);

    final latestComment = firstMap(detail, ['latest_comment', 'recent_comment']) ??
        firstMapFromList(detail, ['latest_comments', 'recent_comments', 'comments']);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: role == 'admin' ? [Colors.indigo.shade400, Colors.indigo.shade800] : AppTheme.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                left: 20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 6)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (detail['name']?.toString().isNotEmpty ?? false)
                        ? detail['name'].toString().substring(0, 1).toUpperCase()
                        : 'U',
                    style: GoogleFonts.nunito(color: roleColor, fontWeight: FontWeight.w800, fontSize: 36),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 20,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    foregroundColor: roleColor,
                    side: const BorderSide(color: Colors.transparent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => args.onEditUser(detail),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: Text('Ubah Profil', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 55),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        detail['name']?.toString() ?? '-',
                        style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    UserDetailBadge(
                      label: isActive ? 'Aktif' : 'Nonaktif',
                      color: isActive ? AppTheme.primary : AppTheme.danger,
                      icon: isActive ? Icons.check_circle_rounded : Icons.block_rounded,
                    ),
                    UserDetailBadge(
                      label: role == 'admin' ? 'Admin' : 'User',
                      color: roleColor,
                      icon: role == 'admin' ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                    ),
                    if (isEmailVerified)
                      const UserDetailBadge(label: 'Email Verified', color: AppTheme.primary, icon: Icons.verified_rounded),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      UserDetailContactRow(icon: Icons.email_outlined, text: detail['email']?.toString() ?? '-'),
                      const SizedBox(height: 12),
                      UserDetailContactRow(
                        icon: Icons.phone_outlined,
                        text: firstString(detail, ['phone', 'phone_number', 'no_hp', 'nomor_telepon'], fallback: '-'),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.textSecondary),
                          const SizedBox(width: 12),
                          Text('Bergabung: ', style: GoogleFonts.nunito(color: AppTheme.textSecondary)),
                          Expanded(
                            child: Text(
                              formatUserDate(detail['created_at']),
                              style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width < 620 ? 1 : 2;
                    final itemWidth = (width - (12 * (crossAxisCount - 1))) / crossAxisCount;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: UserDetailStatCard(
                              title: 'Total Keluhan', value: totalComplaintsFinal.toString(), icon: Icons.report_problem_outlined),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: UserDetailStatCard(title: 'Selesai', value: resolvedComplaints.toString(), icon: Icons.task_alt_rounded),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: UserDetailStatCard(
                              title: 'Pending', value: pendingComplaints.toString(), icon: Icons.pending_actions_rounded),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: UserDetailStatCard(title: 'Komentar', value: totalComments.toString(), icon: Icons.comment_outlined),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                UserDetailSectionHeader(
                  title: 'Keluhan Terbaru',
                  action: TextButton(
                    onPressed: () => args.onShowAllComplaints(detail),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                    child: Text('Lihat Semua', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
                if (latestComplaint == null)
                  const UserDetailEmptyTile(title: 'Belum ada keluhan', subtitle: 'Pengguna ini belum pernah membuat keluhan.')
                else
                  UserComplaintPreviewCard(complaint: latestComplaint),
                const SizedBox(height: 24),
                const UserDetailSectionHeader(title: 'Komentar Terbaru'),
                const SizedBox(height: 8),
                if (latestComment == null)
                  const UserDetailEmptyTile(title: 'Belum ada komentar', subtitle: 'Pengguna ini belum pernah memberikan komentar.')
                else
                  UserCommentPreviewCard(comment: latestComment),
                const SizedBox(height: 24),
                const UserDetailSectionHeader(title: 'Detail Alamat'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      UserDetailRow(icon: Icons.location_on_outlined, label: 'Alamat', value: detail['address']?.toString() ?? '-'),
                      const Divider(height: 20),
                      UserDetailRow(
                          icon: Icons.account_balance_outlined,
                          label: 'RT',
                          value: firstString(detail, ['rt_number', 'rt'], fallback: '-')),
                      const Divider(height: 20),
                      UserDetailRow(
                          icon: Icons.home_work_outlined,
                          label: 'RW',
                          value: firstString(detail, ['rw_number', 'rw'], fallback: '-')),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const UserDetailSectionHeader(title: 'Verifikasi Identitas'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserDetailRow(icon: Icons.badge_outlined, label: 'NIK', value: detail['nik']?.toString() ?? '-'),
                      const Divider(height: 20),
                      Text('Status KTP', style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          UserDetailBadge(
                            label: isVerified ? 'Terverifikasi' : 'Belum Terverifikasi',
                            color: isVerified ? AppTheme.primary : AppTheme.warning,
                            icon: isVerified ? Icons.check_circle_rounded : Icons.warning_rounded,
                          ),
                          const Spacer(),
                          Text(formatUserDate(detail['verified_at'] ?? detail['updated_at']),
                              style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      UserKtpCard(
                        userName: detail['name']?.toString() ?? 'Pengguna',
                        ktpUrl: firstString(detail, ['ktp_url', 'ktp_path'], fallback: ''),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const UserDetailSectionHeader(title: 'Aksi Verifikasi'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isVerified ? AppTheme.warning : AppTheme.primary,
                        side: BorderSide(color: isVerified ? AppTheme.warning : AppTheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        context.pop();
                        args.onToggleVerification(detail, shouldVerify: !isVerified);
                      },
                      icon: Icon(isVerified ? Icons.undo_rounded : Icons.verified_user_rounded, size: 18),
                      label: Text(isVerified ? 'Batalkan Verifikasi' : 'Verifikasi User', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isEmailVerified ? AppTheme.warning : AppTheme.primary,
                        side: BorderSide(color: isEmailVerified ? AppTheme.warning : AppTheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        context.pop();
                        args.onToggleEmailVerification(detail, shouldVerify: !isEmailVerified);
                      },
                      icon: Icon(isEmailVerified ? Icons.mark_email_unread_rounded : Icons.mark_email_read_rounded, size: 18),
                      label: Text(isEmailVerified ? 'Batalkan Verif Email' : 'Verifikasi Email', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const UserDetailSectionHeader(title: 'Aksi Pengguna'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => args.onEditUser(detail),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text('Edit Pengguna', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.pop();
                        args.onToggleStatus(detail);
                      },
                      icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 18),
                      label: Text(isActive ? 'Nonaktifkan' : 'Aktifkan', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isActive ? AppTheme.warning : AppTheme.primary,
                        side: BorderSide(color: isActive ? AppTheme.warning : AppTheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => args.onResetPassword(id, userName: detail['name']?.toString()),
                      icon: const Icon(Icons.lock_reset_rounded, size: 18),
                      label: Text('Reset Password', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.textSecondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.pop();
                        args.onDelete(detail);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text('Hapus', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: const BorderSide(color: AppTheme.danger),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
