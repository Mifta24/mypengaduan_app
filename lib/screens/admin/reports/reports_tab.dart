import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/complaint_model.dart';
import '../../../providers/reports_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/admin_info_card.dart';
import '../../complaints/complaint_detail_screen.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();

  void reload() {}
}

class _AdminReportsTabState extends State<AdminReportsTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late ReportsProvider _reportsProvider;
  bool _providerBound = false;

  late final TabController _tabController;

  Map<String, dynamic>? get _overview => _reportsProvider.overview;
  Map<String, dynamic>? get _complaintsReport => _reportsProvider.complaintsReport;
  Map<String, dynamic>? get _statistics => _reportsProvider.statistics;

  List<Map<String, dynamic>> get _filteredComplaintItems => _reportsProvider.filteredComplaintItems;
  List<Map<String, dynamic>> get _filteredUserItems => _reportsProvider.filteredUserItems;

  bool get _hasLoadedData => _reportsProvider.hasLoadedData;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    debugPrint('📊 [AdminReportsTab] Screen initialized - will load after visible');
  }

  bool _hasLoadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_providerBound) {
      _reportsProvider = context.read<ReportsProvider>();
      _reportsProvider.addListener(_onProviderChanged);
      _providerBound = true;
    }

    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_hasLoadedData) {
          debugPrint('📊 [AdminReportsTab] Screen visible - loading reports now');
          _loadReports();
        }
      });
    }
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_providerBound) {
      _reportsProvider.removeListener(_onProviderChanged);
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports({bool forceRefresh = false}) async {
    try {
      await _reportsProvider.loadReports(forceRefresh: forceRefresh);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat laporan: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _exportReport(String type, String format) async {
    try {
      final message = await _reportsProvider.exportReport(type, format);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        _buildHeader(),
        if (!_hasLoadedData)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else ...[
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primary,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: AppTheme.primary,
              tabs: const [
                Tab(text: 'Ringkasan'),
                Tab(text: 'Keluhan'),
                Tab(text: 'Pengguna'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: () => _loadReports(forceRefresh: true),
                  child: _buildOverviewSection(),
                ),
                RefreshIndicator(
                  onRefresh: () => _loadReports(forceRefresh: true),
                  child: _buildComplaintReportPage(),
                ),
                RefreshIndicator(
                  onRefresh: () => _loadReports(forceRefresh: true),
                  child: _buildUserReportPage(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd   = weekStart.add(const Duration(days: 6));
    final fmt = DateFormat('d MMM', 'id_ID');
    final dateLabel = '${fmt.format(weekStart)} – ${fmt.format(weekEnd)} ${weekEnd.year}';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: 'week',
                style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textPrimary),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                items: [
                  DropdownMenuItem(value: 'week', child: Text('Minggu Ini', style: GoogleFonts.nunito(fontSize: 13))),
                  DropdownMenuItem(value: 'month', child: Text('Bulan Ini', style: GoogleFonts.nunito(fontSize: 13))),
                  DropdownMenuItem(value: 'all', child: Text('Semua', style: GoogleFonts.nunito(fontSize: 13))),
                ],
                onChanged: (_) => _loadReports(forceRefresh: true),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      dateLabel,
                      style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _exportReport('complaints', 'pdf'),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
            tooltip: 'Export PDF',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            onPressed: () => _exportReport('complaints', 'excel'),
            icon: const Icon(Icons.table_chart, color: Colors.green, size: 20),
            tooltip: 'Export Excel',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    final overviewData = (_overview?['data'] as Map<String, dynamic>?) ?? {};
    final stats = (overviewData['statistics'] as Map<String, dynamic>?) ?? {};

    final totalComplaints = _toInt(stats['total_complaints'] ?? overviewData['total_complaints']);
    final byStatus = ((_statistics?['data'] as Map<String, dynamic>?)?['by_status'] as Map<String, dynamic>?) ??
        ((overviewData['complaints_by_status'] as Map<String, dynamic>?) ?? {});
    final resolved   = _toInt(byStatus['resolved']   ?? byStatus['completed']);
    final pending    = _toInt(byStatus['pending']);
    final inProgress = _toInt(byStatus['in_progress'] ?? byStatus['processing']);
    final rejected   = _toInt(byStatus['rejected']);
    final avgResponse = _extractAvgResponseHours();

    final byCategory = ((_statistics?['data'] as Map<String, dynamic>?)?['by_category'] as List?) ?? [];
    final topCategories = byCategory.whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .take(5)
        .toList();
    final maxCat = topCategories.isEmpty ? 1 :
        topCategories.map((c) => _toInt(c['total'] ?? c['count'])).reduce(math.max);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary stat cards ──────────────────────────────
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _summaryCard('Total Pengaduan', '$totalComplaints', AppTheme.primary, Icons.assignment_rounded),
              _summaryCard('Selesai', '$resolved', const Color(0xFF059669), Icons.check_circle_rounded),
              _summaryCard('Ditolak', '$rejected', const Color(0xFFDC2626), Icons.cancel_rounded),
              _summaryCard('Rata-rata Waktu', '${avgResponse.toStringAsFixed(1)} hari', const Color(0xFF0891B2), Icons.timer_rounded),
            ],
          ),
          const SizedBox(height: 24),

          // ── Distribusi Status (pie chart) ───────────────────
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
                    style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      width: 120, height: 120,
                      child: CustomPaint(
                        painter: _PieChartPainter(
                          segments: [
                            (resolved.toDouble(),   AppTheme.primary),
                            (inProgress.toDouble(), const Color(0xFF0891B2)),
                            (pending.toDouble(),     const Color(0xFFD97706)),
                            (rejected.toDouble(),    const Color(0xFFDC2626)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legendItem('Selesai',   resolved,   AppTheme.primary, totalComplaints),
                          _legendItem('Diproses',  inProgress, const Color(0xFF0891B2), totalComplaints),
                          _legendItem('Menunggu',  pending,    const Color(0xFFD97706), totalComplaints),
                          _legendItem('Ditolak',   rejected,   const Color(0xFFDC2626), totalComplaints),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Pengaduan per Kategori (bar chart) ──────────────
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
                      style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 14),
                  ...topCategories.map((cat) {
                    final name  = cat['category']?.toString() ?? cat['category_name']?.toString() ?? 'Kategori';
                    final count = _toInt(cat['total'] ?? cat['count']);
                    final ratio = maxCat == 0 ? 0.0 : count / maxCat;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(name,
                                style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 12,
                                backgroundColor: Colors.grey.shade100,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$count',
                              style: GoogleFonts.nunito(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
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

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
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
                      fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int count, Color color, int total) {
    final pct = total == 0 ? 0.0 : count / total * 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textPrimary))),
          Text('$count (${pct.toStringAsFixed(1)}%)',
              style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildComplaintReportPage() {
    final total = _filteredComplaintItems.length;
    final pending = _filteredComplaintItems.where((c) => _normalizeComplaintStatus(c['status']?.toString() ?? '') == 'pending').length;
    final progress = _filteredComplaintItems.where((c) => _normalizeComplaintStatus(c['status']?.toString() ?? '') == 'in_progress').length;
    final resolved = _filteredComplaintItems.where((c) => _normalizeComplaintStatus(c['status']?.toString() ?? '') == 'resolved').length;
    final rejected = _filteredComplaintItems.where((c) => _normalizeComplaintStatus(c['status']?.toString() ?? '') == 'rejected').length;

    final resolutionRate = total == 0 ? 0.0 : (resolved / total * 100);
    final avgResponse = _extractAvgResponseHours();

    return SingleChildScrollView(
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
                    const Text('Laporan Keluhan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Laporan detail dan analisis keluhan pengguna', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width < 560 ? 2 : 3;
              final itemWidth = (width - (8 * (crossAxisCount - 1))) / crossAxisCount;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(width: itemWidth, child: _smallMetric('Total', '$total')),
                  SizedBox(width: itemWidth, child: _smallMetric('Pending', '$pending')),
                  SizedBox(width: itemWidth, child: _smallMetric('Dalam Proses', '$progress')),
                  SizedBox(width: itemWidth, child: _smallMetric('Selesai', '$resolved')),
                  SizedBox(width: itemWidth, child: _smallMetric('Ditolak', '$rejected')),
                  SizedBox(
                    width: itemWidth,
                    child: _smallMetric('Tingkat Selesai', '${resolutionRate.toStringAsFixed(0)}%'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          _smallMetric('Rata-rata Respon', '${avgResponse.toStringAsFixed(1)} jam', fullWidth: true),
          const SizedBox(height: 12),
          const Text('Daftar Keluhan', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Total $total keluhan ditemukan'),
          const SizedBox(height: 8),
          if (_filteredComplaintItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('Belum ada data keluhan untuk filter ini.'),
            )
          else
            ..._filteredComplaintItems.map(_complaintReportCard),
        ],
      ),
    );
  }

  Widget _buildUserReportPage() {
    final total = _filteredUserItems.length;
    final active = _filteredUserItems.where((u) => _toBool(u['is_active'])).length;
    final inactive = total - active;
    final monthCount = _filteredUserItems.where((u) {
      final created = _parseDate(u['created_at']);
      if (created == null) return false;
      final now = DateTime.now();
      return created.year == now.year && created.month == now.month;
    }).length;

    return SingleChildScrollView(
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
                    const Text('Laporan Pengguna', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Laporan detail dan analisis pengguna sistem', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
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
                  SizedBox(width: itemWidth, child: _smallMetric('Total Pengguna', '$total')),
                  SizedBox(width: itemWidth, child: _smallMetric('Aktif', '$active')),
                  SizedBox(width: itemWidth, child: _smallMetric('Tidak Aktif', '$inactive')),
                  SizedBox(width: itemWidth, child: _smallMetric('Bulan Ini', '$monthCount')),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const Text('Daftar Pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Total $total pengguna ditemukan'),
          const SizedBox(height: 8),
          if (_filteredUserItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('Belum ada data pengguna untuk filter ini.'),
            )
          else
            ..._filteredUserItems.map(_userReportCard),
        ],
      ),
    );
  }

  Widget _smallMetric(String title, String value, {bool fullWidth = false}) {
    final widget = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.08), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
    );

    if (fullWidth) return widget;
    return widget;
  }

  Widget _statusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  Widget _complaintReportCard(Map<String, dynamic> complaint) {
    final title = complaint['title']?.toString() ?? complaint['description']?.toString() ?? '-';
    final status = _statusText(_normalizeComplaintStatus(complaint['status']?.toString() ?? ''));
    final statusColor = _statusColor(_normalizeComplaintStatus(complaint['status']?.toString() ?? ''));
    final userName = _complaintUserName(complaint);
    final category = _complaintCategoryName(complaint);
    final location = _firstString(complaint, ['address', 'location', 'full_address'], fallback: '-');
    final priority = _firstString(complaint, ['priority'], fallback: 'Sedang');
    final created = _parseDate(complaint['created_at']);

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
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(userName, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        const SizedBox(width: 12),
                        Icon(Icons.category, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(category, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          created == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(created),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Prioritas: $priority',
                            style: TextStyle(color: Colors.blue[700], fontSize: 11),
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
                try {
                  final model = Complaint.fromJson(complaint);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaint: model)),
                  );
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Detail keluhan tidak tersedia')),
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Lihat Detail', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userReportCard(Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? '-';
    final email = user['email']?.toString() ?? '-';
    final phone = user['phone']?.toString() ?? '';
    final isActive = _toBool(user['is_active']);
    final complaintsCount = _toInt(user['complaints_count']);
    final created = _parseDate(user['created_at']);
    final lastLogin = _parseDate(user['last_login_at']);
    final emailVerified = _toBool(user['is_email_verified']) || user['email_verified_at'] != null;

    final initials = _initials(name);

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
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
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
                Text(phone, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
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
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(emailVerified ? Icons.verified : Icons.warning_amber,
                  size: 14, color: emailVerified ? Colors.blue : Colors.orange),
              const SizedBox(width: 6),
              Text(
                emailVerified ? 'Email terverifikasi' : 'Email belum terverifikasi',
                style: TextStyle(
                  color: emailVerified ? Colors.blue[700] : Colors.orange[700],
                  fontSize: 13,
                ),
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
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                lastLogin == null ? 'Belum pernah login' : 'Login: ${DateFormat('dd/MM/yy HH:mm').format(lastLogin)}',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => _showUserDetailInline(user),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Detail', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetailInline(Map<String, dynamic> user) {
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
              Text('Status: ${_toBool(user['is_active']) ? 'Aktif' : 'Tidak Aktif'}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  String _complaintCategoryName(Map<String, dynamic> complaint) {
    return _reportsProvider.complaintCategoryName(complaint);
  }

  String _complaintUserName(Map<String, dynamic> complaint) {
    return _reportsProvider.complaintUserName(complaint);
  }

  String _normalizeComplaintStatus(String status) {
    return _reportsProvider.normalizeComplaintStatus(status);
  }

  String _statusText(String normalizedStatus) {
    switch (normalizedStatus) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'Dalam Proses';
      case 'resolved':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return normalizedStatus;
    }
  }

  Color _statusColor(String normalizedStatus) {
    switch (normalizedStatus) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  double _extractAvgResponseHours() {
    final stats = (_complaintsReport?['statistics'] as Map<String, dynamic>?) ??
        ((_overview?['data'] as Map<String, dynamic>?) ?? {});

    final raw = stats['avg_response_time'] ?? stats['average_response_time'] ?? stats['avg_response_hours'];
    if (raw == null) return 0;

    if (raw is num) return raw.toDouble();

    final text = raw.toString().toLowerCase();
    final number = double.tryParse(RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(text)?.group(1) ?? '0') ?? 0;

    if (text.contains('day') || text.contains('hari')) {
      return number * 24;
    }

    return number;
  }

  DateTime? _parseDate(dynamic value) {
    return _reportsProvider.parseDate(value);
  }

  String _firstString(Map<String, dynamic> source, List<String> keys, {String fallback = '-'}) {
    return _reportsProvider.firstString(source, keys, fallback: fallback);
  }

  bool _toBool(dynamic value) {
    return _reportsProvider.toBool(value);
  }

  int _toInt(dynamic value) {
    return _reportsProvider.toInt(value);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'US';
    if (parts.length == 1) {
      final p = parts.first;
      return p.length >= 2 ? p.substring(0, 2).toUpperCase() : p.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

// ─── Pie Chart Painter ────────────────────────────────────────────────────────
class _PieChartPainter extends CustomPainter {
  final List<(double, Color)> segments;
  const _PieChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold(0.0, (s, e) => s + e.$1);
    if (total == 0) return;

    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = size.width * 0.28;
    final radius = size.width / 2 * 0.72;
    final center = Offset(size.width / 2, size.height / 2);
    final smallRect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweep = seg.$1 / total * 2 * math.pi;
      paint.color = seg.$2;
      canvas.drawArc(smallRect, startAngle, sweep - 0.04, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter old) => old.segments != segments;
}
