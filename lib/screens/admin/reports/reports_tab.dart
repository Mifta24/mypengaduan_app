import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/complaint_model.dart';
import '../../../providers/reports_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/admin_section_header.dart';
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
  Map<String, dynamic>? get _usersReport => _reportsProvider.usersReport;
  Map<String, dynamic>? get _statistics => _reportsProvider.statistics;

  List<Map<String, dynamic>> get _filteredComplaintItems => _reportsProvider.filteredComplaintItems;
  List<Map<String, dynamic>> get _filteredUserItems => _reportsProvider.filteredUserItems;

  DateTime? get _complaintFromDate => _reportsProvider.complaintFromDate;
  set _complaintFromDate(DateTime? value) => _reportsProvider.complaintFromDate = value;

  DateTime? get _complaintToDate => _reportsProvider.complaintToDate;
  set _complaintToDate(DateTime? value) => _reportsProvider.complaintToDate = value;

  String get _complaintStatusFilter => _reportsProvider.complaintStatusFilter;
  set _complaintStatusFilter(String value) => _reportsProvider.complaintStatusFilter = value;

  String get _complaintCategoryFilter => _reportsProvider.complaintCategoryFilter;
  set _complaintCategoryFilter(String value) => _reportsProvider.complaintCategoryFilter = value;

  DateTime? get _userFromDate => _reportsProvider.userFromDate;
  set _userFromDate(DateTime? value) => _reportsProvider.userFromDate = value;

  DateTime? get _userToDate => _reportsProvider.userToDate;
  set _userToDate(DateTime? value) => _reportsProvider.userToDate = value;

  String get _userStatusFilter => _reportsProvider.userStatusFilter;
  set _userStatusFilter(String value) => _reportsProvider.userStatusFilter = value;

  String get _userSearchQuery => _reportsProvider.userSearchQuery;
  set _userSearchQuery(String value) => _reportsProvider.userSearchQuery = value;

  bool get _hasLoadedData => _reportsProvider.hasLoadedData;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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

  Future<void> _applyComplaintFilter() {
    return _reportsProvider.applyComplaintFilter();
  }

  Future<void> _applyUserFilter() {
    return _reportsProvider.applyUserFilter();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: !_hasLoadedData
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _loadReports(forceRefresh: true),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildOverviewSection(),
                      const SizedBox(height: 16),
                      _buildReportsContainer(),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: const AdminSectionHeader(
        title: 'Manajemen Laporan',
        subtitle: 'Pantau statistik sistem dan laporan detail pengguna.',
        icon: Icons.assessment,
      ),
    );
  }

  Widget _buildOverviewSection() {
    final overviewData = (_overview?['data'] as Map<String, dynamic>?) ?? {};
    final stats = (overviewData['statistics'] as Map<String, dynamic>?) ?? {};

    final totalComplaints = _toInt(
      stats['total_complaints'] ?? overviewData['total_complaints'],
    );
    final totalUsers = _toInt(stats['total_users'] ?? overviewData['total_users']);
    final totalCategories = _toInt(
      stats['total_categories'] ?? overviewData['total_categories'],
    );
    final totalAnnouncements = _toInt(
      stats['total_announcements'] ?? overviewData['total_announcements'],
    );

    final byStatus = ((_statistics?['data'] as Map<String, dynamic>?)?['by_status'] as Map<String, dynamic>?) ??
        ((overviewData['complaints_by_status'] as Map<String, dynamic>?) ?? {});

    final resolved = _toInt(byStatus['resolved'] ?? byStatus['completed']);
    final pending = _toInt(byStatus['pending']);
    final inProgress = _toInt(byStatus['in_progress'] ?? byStatus['processing']);
    final rejected = _toInt(byStatus['rejected']);

    final resolutionRate = totalComplaints == 0 ? 0.0 : (resolved / totalComplaints * 100);
    final avgResponse = _extractAvgResponseHours();

    final byCategory = ((_statistics?['data'] as Map<String, dynamic>?)?['by_category'] as List?) ?? [];
    final topCategories = byCategory.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).take(5).toList();

    final complaintsMonth = _toInt(
      ((_complaintsReport?['statistics'] as Map<String, dynamic>?)?['this_month']),
    );
    final usersMonth = _toInt(((_usersReport?['statistics'] as Map<String, dynamic>?)?['this_month']));
    final commentsMonth = _toInt(
      ((_overview?['data'] as Map<String, dynamic>?)?['new_comments_30_days']) ??
          ((_overview?['data'] as Map<String, dynamic>?)?['comments_this_month']),
    );

    return Column(
      children: [
        _summarySectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ringkasan Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                'Pantau performa keluhan dan pengguna dalam satu tampilan.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isNarrow = width < 520;
                  final cardWidth = isNarrow ? width : (width - 10) / 2;

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _overviewCard('Total Keluhan', '$totalComplaints', '+$complaintsMonth bulan ini'),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _overviewCard('Total Pengguna', '$totalUsers', '+$usersMonth bulan ini'),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _overviewCard('Total Kategori', '$totalCategories', 'Aktif dan tidak aktif'),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _overviewCard('Total Pengumuman', '$totalAnnouncements', 'Semua pengumuman'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 520;
                  if (isNarrow) {
                    return Column(
                      children: [
                        _overviewCard(
                          'Tingkat Penyelesaian',
                          '${resolutionRate.toStringAsFixed(0)}%',
                          'dari total keluhan',
                        ),
                        const SizedBox(height: 8),
                        _overviewCard(
                          'Rata-rata Waktu Respon',
                          '${avgResponse.toStringAsFixed(1)} jam',
                          'Waktu rata-rata dari keluhan dibuat hingga direspon',
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _overviewCard(
                          'Tingkat Penyelesaian',
                          '${resolutionRate.toStringAsFixed(0)}%',
                          'dari total keluhan',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _overviewCard(
                          'Rata-rata Waktu Respon',
                          '${avgResponse.toStringAsFixed(1)} jam',
                          'Waktu rata-rata dari keluhan dibuat hingga direspon',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _summarySectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Distribusi Status Keluhan', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _statusRow('Dalam Proses', inProgress, Colors.blue),
              _statusRow('Pending', pending, Colors.orange),
              _statusRow('Selesai', resolved, Colors.green),
              if (rejected > 0) _statusRow('Ditolak', rejected, Colors.red),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _summarySectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Top 5 Kategori', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (topCategories.isEmpty)
                Text('Belum ada data kategori', style: TextStyle(color: Colors.grey.shade600))
              else
                ...topCategories.map((cat) {
                  final name = cat['category']?.toString() ?? cat['category_name']?.toString() ?? 'Kategori';
                  final count = _toInt(cat['total'] ?? cat['count']);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.category_outlined, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(name)),
                        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _summarySectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Aktivitas Terbaru (30 Hari Terakhir)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 520;
                  if (isNarrow) {
                    return Column(
                      children: [
                        _activityCard('$complaintsMonth', 'Keluhan Baru'),
                        const SizedBox(height: 8),
                        _activityCard('$commentsMonth', 'Komentar Baru'),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: _activityCard('$complaintsMonth', 'Keluhan Baru')),
                      const SizedBox(width: 8),
                      Expanded(child: _activityCard('$commentsMonth', 'Komentar Baru')),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text('Aksi Cepat', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _tabController.animateTo(0),
                    icon: const Icon(Icons.description),
                    label: const Text('Laporan Keluhan'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _tabController.animateTo(1),
                    icon: const Icon(Icons.people),
                    label: const Text('Laporan Pengguna'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportsContainer() {
    final viewportHeight = MediaQuery.of(context).size.height;
    final contentHeight = (viewportHeight - 250).clamp(620.0, 1000.0);

    return SizedBox(
      height: contentHeight,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              color: Colors.grey.shade50,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: AppTheme.primary,
                tabs: const [
                  Tab(text: 'Laporan Keluhan'),
                  Tab(text: 'Laporan Pengguna'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildComplaintReportPage(),
                  _buildUserReportPage(),
                ],
              ),
            ),
          ],
        ),
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
          const Text('Laporan Keluhan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Laporan detail dan analisis keluhan pengguna'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _exportReport('complaints', 'pdf'),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
              ),
              OutlinedButton.icon(
                onPressed: () => _exportReport('complaints', 'excel'),
                icon: const Icon(Icons.table_chart),
                label: const Text('Export Excel'),
              ),
              OutlinedButton.icon(
                onPressed: _reportsProvider.hasSelectedComplaints
                    ? () => _exportSelectedComplaints('pdf')
                    : null,
                icon: const Icon(Icons.check_box),
                label: Text('Export Dipilih PDF (${_reportsProvider.selectedComplaintCount})'),
              ),
              OutlinedButton.icon(
                onPressed: _reportsProvider.hasSelectedComplaints
                    ? () => _exportSelectedComplaints('excel')
                    : null,
                icon: const Icon(Icons.checklist),
                label: Text('Export Dipilih Excel (${_reportsProvider.selectedComplaintCount})'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _filteredComplaintItems.isEmpty
                    ? null
                    : () => _reportsProvider.selectAllFilteredComplaints(),
                child: const Text('Pilih Semua (Filter Saat Ini)'),
              ),
              OutlinedButton(
                onPressed: _reportsProvider.hasSelectedComplaints
                    ? () => _reportsProvider.clearSelectedComplaints()
                    : null,
                child: const Text('Hapus Pilihan'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilterPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dateRow(
                  fromLabel: 'Dari Tanggal',
                  toLabel: 'Sampai Tanggal',
                  fromDate: _complaintFromDate,
                  toDate: _complaintToDate,
                  onPickFrom: () async {
                    final picked = await _pickDate(_complaintFromDate);
                    if (picked == null) return;
                    setState(() => _complaintFromDate = picked);
                  },
                  onPickTo: () async {
                    final picked = await _pickDate(_complaintToDate);
                    if (picked == null) return;
                    setState(() => _complaintToDate = picked);
                  },
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 620;
                    if (isNarrow) {
                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            key: ValueKey('complaint_status_$_complaintStatusFilter'),
                            initialValue: _complaintStatusFilter,
                            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Semua Status')),
                              DropdownMenuItem(value: 'pending', child: Text('Pending')),
                              DropdownMenuItem(value: 'in_progress', child: Text('Dalam Proses')),
                              DropdownMenuItem(value: 'resolved', child: Text('Selesai')),
                              DropdownMenuItem(value: 'rejected', child: Text('Ditolak')),
                            ],
                            onChanged: (value) => setState(() => _complaintStatusFilter = value ?? 'all'),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            key: ValueKey('complaint_category_$_complaintCategoryFilter'),
                            initialValue: _complaintCategoryFilter,
                            decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('Semua Kategori')),
                              ..._allComplaintCategories().map(
                                (cat) => DropdownMenuItem(value: cat.toLowerCase(), child: Text(cat)),
                              ),
                            ],
                            onChanged: (value) => setState(() => _complaintCategoryFilter = value ?? 'all'),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('complaint_status_$_complaintStatusFilter'),
                            initialValue: _complaintStatusFilter,
                            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Semua Status')),
                              DropdownMenuItem(value: 'pending', child: Text('Pending')),
                              DropdownMenuItem(value: 'in_progress', child: Text('Dalam Proses')),
                              DropdownMenuItem(value: 'resolved', child: Text('Selesai')),
                              DropdownMenuItem(value: 'rejected', child: Text('Ditolak')),
                            ],
                            onChanged: (value) => setState(() => _complaintStatusFilter = value ?? 'all'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('complaint_category_$_complaintCategoryFilter'),
                            initialValue: _complaintCategoryFilter,
                            decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('Semua Kategori')),
                              ..._allComplaintCategories().map(
                                (cat) => DropdownMenuItem(value: cat.toLowerCase(), child: Text(cat)),
                              ),
                            ],
                            onChanged: (value) => setState(() => _complaintCategoryFilter = value ?? 'all'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        setState(() {
                          _complaintFromDate = now.subtract(const Duration(days: 31));
                          _complaintToDate = now;
                          _complaintStatusFilter = 'all';
                          _complaintCategoryFilter = 'all';
                          _reportsProvider.clearSelectedComplaints();
                        });
                        await _applyComplaintFilter();
                      },
                      child: const Text('Reset'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _applyComplaintFilter();
                      },
                      child: const Text('Filter'),
                    ),
                  ],
                ),
              ],
            ),
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
          const Text('Laporan Pengguna', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Laporan detail dan analisis pengguna sistem'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _exportReport('users', 'pdf'),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
              ),
              OutlinedButton.icon(
                onPressed: () => _exportReport('users', 'excel'),
                icon: const Icon(Icons.table_chart),
                label: const Text('Export Excel'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilterPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dateRow(
                  fromLabel: 'Dari Tanggal',
                  toLabel: 'Sampai Tanggal',
                  fromDate: _userFromDate,
                  toDate: _userToDate,
                  onPickFrom: () async {
                    final picked = await _pickDate(_userFromDate);
                    if (picked == null) return;
                    setState(() => _userFromDate = picked);
                  },
                  onPickTo: () async {
                    final picked = await _pickDate(_userToDate);
                    if (picked == null) return;
                    setState(() => _userToDate = picked);
                  },
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 620;
                    if (isNarrow) {
                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            key: ValueKey('user_status_$_userStatusFilter'),
                            initialValue: _userStatusFilter,
                            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Semua Status')),
                              DropdownMenuItem(value: 'active', child: Text('Aktif')),
                              DropdownMenuItem(value: 'inactive', child: Text('Tidak Aktif')),
                            ],
                            onChanged: (value) => setState(() => _userStatusFilter = value ?? 'all'),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: _userSearchQuery,
                            decoration: const InputDecoration(
                              labelText: 'Cari',
                              hintText: 'Nama atau email...',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) => _userSearchQuery = value,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('user_status_$_userStatusFilter'),
                            initialValue: _userStatusFilter,
                            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('Semua Status')),
                              DropdownMenuItem(value: 'active', child: Text('Aktif')),
                              DropdownMenuItem(value: 'inactive', child: Text('Tidak Aktif')),
                            ],
                            onChanged: (value) => setState(() => _userStatusFilter = value ?? 'all'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: _userSearchQuery,
                            decoration: const InputDecoration(
                              labelText: 'Cari',
                              hintText: 'Nama atau email...',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) => _userSearchQuery = value,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        setState(() {
                          _userFromDate = now.subtract(const Duration(days: 31));
                          _userToDate = now;
                          _userStatusFilter = 'all';
                          _userSearchQuery = '';
                        });
                        await _applyUserFilter();
                      },
                      child: const Text('Reset'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _applyUserFilter();
                      },
                      child: const Text('Filter'),
                    ),
                  ],
                ),
              ],
            ),
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

  Widget _dateRow({
    required String fromLabel,
    required String toLabel,
    required DateTime? fromDate,
    required DateTime? toDate,
    required VoidCallback onPickFrom,
    required VoidCallback onPickTo,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 620;
        if (isNarrow) {
          return Column(
            children: [
              _dateField(fromLabel, fromDate, onPickFrom),
              const SizedBox(height: 8),
              _dateField(toLabel, toDate, onPickTo),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _dateField(fromLabel, fromDate, onPickFrom)),
            const SizedBox(width: 8),
            Expanded(child: _dateField(toLabel, toDate, onPickTo)),
          ],
        );
      },
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(value == null ? '-' : DateFormat('MM/dd/yyyy').format(value)),
      ),
    );
  }

  Widget _buildFilterPanel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  Widget _summarySectionCard({required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _overviewCard(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
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
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _activityCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _smallMetric(String title, String value, {bool fullWidth = false}) {
    final widget = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
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
    final selected = _reportsProvider.isComplaintSelected(complaint);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: (_) => _reportsProvider.toggleComplaintSelection(complaint),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(userName),
          Text(category),
          Text(location, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(created == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(created)),
          Text(priority),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
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
              child: const Text('Lihat Detail'),
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
    final userId = _toInt(user['id']);
    final created = _parseDate(user['created_at']);
    final lastLogin = _parseDate(user['last_login_at']);
    final emailVerified = _toBool(user['is_email_verified']) || user['email_verified_at'] != null;

    final initials = _initials(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue.shade100,
                child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(isActive ? 'Aktif' : 'Tidak Aktif', style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(email),
          if (phone.isNotEmpty) Text(phone),
          Text('Bergabung: ${created == null ? '-' : DateFormat('dd/MM/yyyy').format(created)}'),
          Text('$complaintsCount keluhan'),
          Text(lastLogin == null ? 'Belum pernah login' : 'Login terakhir: ${DateFormat('dd/MM/yyyy HH:mm').format(lastLogin)}'),
          Text(emailVerified ? 'Email terverifikasi' : 'Email belum terverifikasi'),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => _showUserDetailInline(user),
                  child: const Text('Lihat Detail'),
                ),
                OutlinedButton(
                  onPressed: userId > 0 ? () => _exportComplaintsByUser(user, 'pdf') : null,
                  child: const Text('Keluhan User PDF'),
                ),
                OutlinedButton(
                  onPressed: userId > 0 ? () => _exportComplaintsByUser(user, 'excel') : null,
                  child: const Text('Keluhan User Excel'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSelectedComplaints(String format) async {
    try {
      final message = await _reportsProvider.exportSelectedComplaints(format);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export pilihan: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _exportComplaintsByUser(Map<String, dynamic> user, String format) async {
    final userId = _toInt(user['id']);
    if (userId <= 0) return;

    final userName = user['name']?.toString() ?? 'User_$userId';

    try {
      final message = await _reportsProvider.exportComplaintsByUser(
        userId: userId,
        userName: userName,
        format: format,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export keluhan user: $e'), backgroundColor: Colors.red),
      );
    }
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

  Future<DateTime?> _pickDate(DateTime? initial) async {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  List<String> _allComplaintCategories() {
    return _reportsProvider.allComplaintCategories();
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
