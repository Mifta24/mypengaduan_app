import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import '../../complaints/complaint_detail_screen.dart';
import '../announcements/add_announcement_screen.dart';
import '../categories/categories_tab.dart';
import '../reports/reports_tab.dart';
import '../users/users_tab.dart';

class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab>
    with AutomaticKeepAliveClientMixin {
  final AdminService _adminService = AdminService();

  int _total = 0;
  int _pending = 0;
  int _processing = 0;
  int _resolved = 0;
  List<dynamic> _recent = [];
  List<int> _chartData = List.filled(7, 0);
  bool _isLoading = false;
  bool _hasLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load({bool force = false}) async {
    if (_isLoading) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) return;

    setState(() => _isLoading = true);
    try {
      final data = await _adminService.getDashboard();
      final d = data['data'] ?? data;
      final complaintsData = d['complaints'] ?? {};
      final recentList = d['recent_complaints'] ?? [];

      if (mounted) {
        setState(() {
          final totalObj = d['total_complaints'];
          _total = totalObj is Map ? (totalObj['count'] ?? 0) : 0;
          _pending = complaintsData['pending'] ?? 0;
          _processing = complaintsData['in_progress'] ?? 0;
          _resolved = complaintsData['resolved'] ?? 0;
          _recent = recentList is List ? recentList.take(5).toList() : [];

          // Build chart from recent complaints (count per day last 7 days)
          final counts = List.filled(7, 0);
          final now = DateTime.now();
          for (final item in (recentList is List ? recentList : [])) {
            if (item is Map && item['created_at'] != null) {
              final dt = DateTime.tryParse(item['created_at'].toString());
              if (dt != null) {
                final diff = now.difference(dt).inDays;
                if (diff >= 0 && diff < 7) counts[6 - diff]++;
              }
            }
          }
          _chartData = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ── Admin info card ──────────────────────────────────
          _buildAdminCard(user?.name ?? 'Admin', user?.role ?? 'Super Admin'),
          const SizedBox(height: 20),

          // ── Stats cards ──────────────────────────────────────
          Text('Ringkasan Hari Ini',
              style: GoogleFonts.nunito(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _statCard('Total Pengaduan', _total, Icons.assignment_rounded,
                  AppTheme.primary, '+12 dari kemarin'),
              _statCard('Menunggu', _pending, Icons.schedule_rounded,
                  const Color(0xFFD97706), '+5 dari kemarin'),
              _statCard('Diproses', _processing, Icons.sync_rounded,
                  const Color(0xFF0891B2), '+8 dari kemarin'),
              _statCard('Selesai', _resolved, Icons.check_circle_rounded,
                  AppTheme.primaryLight, '+15 dari kemarin'),
            ],
          ),
          const SizedBox(height: 24),

          // ── Bar chart ────────────────────────────────────────
          _buildBarChart(),
          const SizedBox(height: 24),

          // ── Recent complaints ─────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pengaduan Terbaru',
                  style: GoogleFonts.nunito(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Text('Lihat Semua',
                    style: GoogleFonts.nunito(
                        fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isLoading && _recent.isEmpty
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppTheme.primary)))
              : _recent.isEmpty
                  ? _emptyState('Belum ada pengaduan')
                  : Column(
                      children: _recent.map((item) => _recentCard(item)).toList()),
          const SizedBox(height: 24),

          // ── Quick actions ─────────────────────────────────────
          Text('Aksi Cepat',
              style: GoogleFonts.nunito(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildAdminCard(String name, String role) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.bgDark, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(name[0].toUpperCase(),
                  style: GoogleFonts.nunito(
                      fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.nunito(
                        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(role,
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Super Admin',
                style: GoogleFonts.nunito(
                    fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color, String sub) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value',
                  style: GoogleFonts.nunito(
                      fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              Text(sub,
                  style: GoogleFonts.nunito(
                      fontSize: 10, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pengaduan 7 Hari Terakhir',
                  style: GoogleFonts.nunito(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text('7 Hari Terakhir',
                    style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _BarChartPainter(data: _chartData),
            ),
          ),
          const SizedBox(height: 8),
          // X-axis labels (last 7 days)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final date = DateTime.now().subtract(Duration(days: 6 - i));
              return Text('${date.day} ${_monthShort(date.month)}',
                  style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.textSecondary));
            }),
          ),
        ],
      ),
    );
  }

  String _monthShort(int m) {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return names[m];
  }

  Widget _recentCard(dynamic item) {
    final title = item['title']?.toString() ?? 'Pengaduan';
    final status = item['status']?.toString() ?? 'pending';
    final category = item['category'] is Map
        ? item['category']['name']?.toString() ?? ''
        : '';
    final location = item['location']?.toString() ?? '';
    final createdAt = item['created_at'] != null
        ? DateTime.tryParse(item['created_at'].toString())
        : null;
    final userName = item['user'] is Map
        ? item['user']['name']?.toString() ?? 'Pengguna'
        : 'Pengguna';

    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);

    return GestureDetector(
      onTap: () {
        final id = item['id'];
        if (id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComplaintDetailScreen(
                  complaintId: id is int ? id : int.tryParse(id.toString())),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            // Colored avatar
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: GoogleFonts.nunito(
                        fontSize: 16, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  if (category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(category,
                          style: GoogleFonts.nunito(
                              fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '${location.isNotEmpty ? location : '-'}  •  ${createdAt != null ? '${createdAt.day} ${_monthShort(createdAt.month)}, ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}' : '-'}',
                    style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(statusLabel,
                  style: GoogleFonts.nunito(
                      fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (Icons.verified_user_rounded, 'Verifikasi\nPending', const Color(0xFFEA580C), () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: AppTheme.surface,
            appBar: AppBar(
              backgroundColor: AppTheme.bgDark,
              title: Text('Manajemen Pengguna',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: const AdminUsersTab(),
          ),
        ));
      }),
      (Icons.add_box_rounded, 'Tambah\nPengumuman', AppTheme.primary, () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddAnnouncementScreen()));
      }),
      (Icons.category_rounded, 'Kelola\nKategori', const Color(0xFF6366F1), () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: AppTheme.surface,
            appBar: AppBar(
              backgroundColor: AppTheme.bgDark,
              title: Text('Kelola Kategori',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: const AdminCategoriesTab(),
          ),
        ));
      }),
      (Icons.bar_chart_rounded, 'Laporan &\nStatistik', AppTheme.secondary, () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: AppTheme.surface,
            appBar: AppBar(
              backgroundColor: AppTheme.bgDark,
              title: Text('Laporan & Statistik',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: const AdminReportsTab(),
          ),
        ));
      }),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: actions.map((a) {
        return GestureDetector(
          onTap: a.$4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: a.$3.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(a.$1, size: 22, color: a.$3),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(a.$2,
                      style: GoogleFonts.nunito(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, height: 1.3)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(msg, style: GoogleFonts.nunito(color: AppTheme.textSecondary)),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFD97706);
      case 'in_progress': return const Color(0xFF0891B2);
      case 'resolved': return AppTheme.primary;
      case 'rejected': return const Color(0xFFDC2626);
      case 'waiting_user_confirmation': return const Color(0xFFEA580C);
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Menunggu';
      case 'in_progress': return 'Diproses';
      case 'resolved': return 'Selesai';
      case 'rejected': return 'Ditolak';
      case 'waiting_user_confirmation': return 'Konfirmasi';
      default: return status;
    }
  }
}

// ─── Bar Chart Painter ────────────────────────────────────────────────────────
class _BarChartPainter extends CustomPainter {
  final List<int> data;
  const _BarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.reduce(math.max).toDouble();
    if (maxVal == 0) return;

    final barW = (size.width - (data.length - 1) * 8) / data.length;
    final paint = Paint()..style = PaintingStyle.fill;

    // Y-axis guide lines
    final guidePaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    for (int i = 0; i < data.length; i++) {
      final barH = (data[i] / maxVal) * size.height;
      final x = i * (barW + 8);
      final y = size.height - barH;

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barW, barH),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );

      paint.color = AppTheme.primary.withValues(alpha: 0.85);
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) => old.data != data;
}