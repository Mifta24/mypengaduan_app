import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';

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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == '1' ||
          normalized == 'true' ||
          normalized == 'yes' ||
          normalized == 'aktif';
    }
    return false;
  }

  int _firstInt(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      if (!source.containsKey(key)) continue;
      return _toInt(source[key]);
    }
    return 0;
  }

  String _firstString(Map<String, dynamic> source, List<String> keys,
      {String fallback = '-'}) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  Map<String, dynamic>? _firstMap(
      Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
    }
    return null;
  }

  Map<String, dynamic>? _firstMapFromList(
      Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is List && value.isNotEmpty) {
        final first = value.first;
        if (first is Map<String, dynamic>) return first;
        if (first is Map) return Map<String, dynamic>.from(first);
      }
    }
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }

  List<Map<String, dynamic>> _extractComplaintList(
      Map<String, dynamic> source) {
    const listKeys = [
      'complaints',
      'latest_complaints',
      'recent_complaints',
      'user_complaints',
    ];
    for (final key in listKeys) {
      final value = source[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const [];
  }

  int _countComplaintsByStatus(
      Map<String, dynamic> source, Set<String> statuses) {
    final normalizedTargets = statuses.map((e) => e.toLowerCase()).toSet();

    const mapKeys = [
      'complaints_by_status',
      'complaint_status_counts',
      'status_counts',
      'statistics',
      'stats',
    ];
    for (final key in mapKeys) {
      final value = source[key];
      if (value is Map) {
        final counts = Map<String, dynamic>.from(value);
        var total = 0;
        for (final target in normalizedTargets) {
          total += _toInt(counts[target]);
        }
        if (total > 0) return total;
      }
    }

    final complaints = _extractComplaintList(source);
    if (complaints.isEmpty) return 0;
    return complaints.where((complaint) {
      final status = complaint['status']?.toString().toLowerCase() ?? '';
      return normalizedTargets.contains(status);
    }).length;
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return '-';
    return DateFormat('d MMMM y').format(date);
  }

  String _timeAgo(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return '-';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return _formatDate(date);
  }

  String _complaintStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'processing':
      case 'in_progress':
        return 'Dalam Proses';
      case 'resolved':
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  Color _complaintStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warning;
      case 'processing':
      case 'in_progress':
        return const Color(0xFF0891B2);
      case 'resolved':
      case 'completed':
        return AppTheme.primary;
      case 'rejected':
        return AppTheme.danger;
      default:
        return Colors.grey;
    }
  }

  void _showKtpImage(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                      child: Text(title,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500, minHeight: 200),
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Gagal memuat gambar KTP'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengguna'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: args.fetchDetail(args.user),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final detail =
              snapshot.data ?? Map<String, dynamic>.from(args.user as Map);
          final id = _toInt(detail['id']);
          final role = detail['role']?.toString() ?? 'user';
          final roleColor = role == 'admin' ? Colors.indigo : Colors.teal;
          final isVerified = _toBool(detail['is_user_verified']) ||
              _toBool(detail['is_verified']);
          final isEmailVerified = _toBool(detail['is_email_verified']) ||
              detail['email_verified_at'] != null;
          final isActive = detail['is_active'] == null
              ? true
              : _toBool(detail['is_active']);

          final totalComplaints = _firstInt(detail, [
            'complaints_count',
            'total_complaints',
            'total_keluhan',
            'resolved_complaints',
            'total_reports',
          ]);
          final resolvedComplaintsRaw = _firstInt(detail, [
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
              : _countComplaintsByStatus(detail, const {'resolved', 'completed'});

          final pendingComplaintsRaw = _firstInt(detail, [
            'pending_complaints_count',
            'pending_count',
            'in_progress_count',
            'pending',
            'in_progress',
            'keluhan_pending',
          ]);

          final pendingComplaints = pendingComplaintsRaw > 0
              ? pendingComplaintsRaw
              : _countComplaintsByStatus(
                  detail, const {'pending', 'in_progress', 'processing'});

          final totalComplaintsFinal = totalComplaints > 0
              ? totalComplaints
              : _extractComplaintList(detail).length;
          final totalComments = _firstInt(detail, [
            'comments_count',
            'total_comments',
            'komentar_count',
          ]);

          final latestComplaint = _firstMap(detail, [
                'latest_complaint',
                'recent_complaint',
              ]) ??
              _firstMapFromList(detail, [
                'latest_complaints',
                'recent_complaints',
                'complaints',
              ]);

          final latestComment = _firstMap(detail, [
                'latest_comment',
                'recent_comment',
              ]) ??
              _firstMapFromList(detail, [
                'latest_comments',
                'recent_comments',
                'comments',
              ]);

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
                          colors: role == 'admin'
                              ? [Colors.indigo.shade400, Colors.indigo.shade800]
                              : AppTheme.primaryGradient,
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
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          (detail['name']?.toString().isNotEmpty ?? false)
                              ? detail['name'].toString().substring(0, 1).toUpperCase()
                              : 'U',
                          style: GoogleFonts.nunito(
                            color: roleColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 36,
                          ),
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
                              style: GoogleFonts.nunito(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildBadge(
                            isActive ? 'Aktif' : 'Nonaktif',
                            isActive ? AppTheme.primary : AppTheme.danger,
                            isActive ? Icons.check_circle_rounded : Icons.block_rounded,
                          ),
                          _buildBadge(
                            role == 'admin' ? 'Admin' : 'User',
                            roleColor,
                            role == 'admin' ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                          ),
                          if (isEmailVerified)
                            _buildBadge(
                              'Email Verified',
                              Colors.blue,
                              Icons.verified_rounded,
                            ),
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
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            _contactRow(Icons.email_outlined, detail['email']?.toString() ?? '-'),
                            const SizedBox(height: 12),
                            _contactRow(Icons.phone_outlined, _firstString(detail, ['phone', 'phone_number', 'no_hp', 'nomor_telepon'], fallback: '-')),
                            const Divider(height: 24),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.textSecondary),
                                const SizedBox(width: 12),
                                Text('Bergabung: ', style: GoogleFonts.nunito(color: AppTheme.textSecondary)),
                                Expanded(
                                  child: Text(
                                    _formatDate(detail['created_at']),
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
                                child: _buildStatCard('Total Keluhan', totalComplaintsFinal.toString(), Icons.report_problem_outlined),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _buildStatCard('Selesai', resolvedComplaints.toString(), Icons.task_alt_rounded),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _buildStatCard('Pending', pendingComplaints.toString(), Icons.pending_actions_rounded),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _buildStatCard('Komentar', totalComments.toString(), Icons.comment_outlined),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'Keluhan Terbaru',
                        action: TextButton(
                          onPressed: () => args.onShowAllComplaints(detail),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                          child: Text('Lihat Semua', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (latestComplaint == null)
                        _buildEmptyTile('Belum ada keluhan', 'Pengguna ini belum pernah membuat keluhan.')
                      else
                        _buildLatestComplaintCard(latestComplaint),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Komentar Terbaru'),
                      const SizedBox(height: 8),
                      if (latestComment == null)
                        _buildEmptyTile('Belum ada komentar', 'Pengguna ini belum pernah memberikan komentar.')
                      else
                        _buildLatestCommentCard(latestComment),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Detail Alamat'),
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
                            _buildDetailRow(Icons.location_on_outlined, 'Alamat', detail['address']?.toString() ?? '-'),
                            const Divider(height: 20),
                            _buildDetailRow(Icons.account_balance_outlined, 'RT', _firstString(detail, ['rt_number', 'rt'], fallback: '-')),
                            const Divider(height: 20),
                            _buildDetailRow(Icons.home_work_outlined, 'RW', _firstString(detail, ['rw_number', 'rw'], fallback: '-')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Verifikasi Identitas'),
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
                            _buildDetailRow(Icons.badge_outlined, 'NIK', detail['nik']?.toString() ?? '-'),
                            const Divider(height: 20),
                            Text('Status KTP', style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _buildBadge(
                                  isVerified ? 'Terverifikasi' : 'Belum Terverifikasi',
                                  isVerified ? AppTheme.primary : AppTheme.warning,
                                  isVerified ? Icons.check_circle_rounded : Icons.warning_rounded,
                                ),
                                const Spacer(),
                                Text(_formatDate(detail['verified_at'] ?? detail['updated_at']), style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildKtpBlock(context, detail),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Aksi Verifikasi'),
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
                              foregroundColor: isEmailVerified ? AppTheme.warning : Colors.blue,
                              side: BorderSide(color: isEmailVerified ? AppTheme.warning : Colors.blue),
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
                      _buildSectionHeader('Aksi Pengguna'),
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
                              foregroundColor: Colors.blueGrey,
                              side: const BorderSide(color: Colors.blueGrey),
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
        },
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
      ],
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? action}) {
    return Row(
      children: [
        Text(title, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const Spacer(),
        if (action != null) action,
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 24),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildLatestComplaintCard(Map<String, dynamic> complaint) {
    final status = complaint['status']?.toString() ?? 'pending';
    final category = _firstString(complaint, ['category_name', 'category', 'category_title'], fallback: 'Tanpa Kategori');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Icon(Icons.category_outlined, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(category, style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 12)),
              const Spacer(),
              Text(_timeAgo(complaint['created_at']), style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          _buildBadge(_complaintStatusText(status), _complaintStatusColor(status), Icons.info_outline_rounded),
        ],
      ),
    );
  }

  Widget _buildLatestCommentCard(Map<String, dynamic> comment) {
    final content = _firstString(comment, ['content', 'comment', 'message'], fallback: '-');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, color: AppTheme.primary.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Expanded(child: Text(content, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
            ],
          ),
          const SizedBox(height: 12),
          Text(_timeAgo(comment['created_at']), style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyTile(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 32, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildKtpBlock(BuildContext context, Map<String, dynamic> detail) {
    final name = detail['name']?.toString() ?? 'Pengguna';
    final ktpUrl = _firstString(detail, ['ktp_url', 'ktp_path'], fallback: '');

    if (ktpUrl.isEmpty) {
      return _buildEmptyTile('KTP Tidak Ada', 'Foto KTP belum diunggah.');
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              ktpUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                color: Colors.grey.shade100,
                child: const Center(child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey)),
              ),
            ),
          ),
          InkWell(
            onTap: () => _showKtpImage(context, ktpUrl, 'KTP $name'),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Text('Lihat Ukuran Penuh', style: GoogleFonts.nunito(color: AppTheme.primary, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _firstString(Map<String, dynamic> source, List<String> keys, {String fallback = '-'}) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String _complaintStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'processing':
      case 'in_progress':
        return 'Dalam Proses';
      case 'resolved':
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  Color _complaintStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warning;
      case 'processing':
      case 'in_progress':
        return const Color(0xFF0891B2);
      case 'resolved':
      case 'completed':
        return AppTheme.primary;
      case 'rejected':
        return AppTheme.danger;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Semua Keluhan - ${args.userName}'),
      ),
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
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              final status = complaint['status']?.toString() ?? 'pending';
              final id = _toInt(complaint['id']);

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: id <= 0
                    ? null
                    : () => context.push('/complaint/$id'),
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
                              color: _complaintStatusColor(status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _complaintStatusText(status),
                              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: _complaintStatusColor(status)),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _firstString(complaint, ['category_name', 'category', 'category_title'], fallback: 'Tanpa Kategori'),
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
        },
      ),
    );
  }
}
