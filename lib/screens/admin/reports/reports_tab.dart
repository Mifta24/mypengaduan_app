import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/reports_provider.dart';
import '../../../theme/app_theme.dart';
import 'widgets/report_complaints_tab.dart';
import 'widgets/report_overview_tab.dart';
import 'widgets/report_users_tab.dart';

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

  bool _hasLoadedOnce = false;
  String _periodFilter = 'all'; // 'week' | 'month' | 'all'

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    debugPrint('📊 [AdminReportsTab] Screen initialized - will load after visible');
  }

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
        if (mounted && !_reportsProvider.hasLoadedData) {
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
      final now = DateTime.now();
      DateTime? from;
      DateTime? to;

      if (_periodFilter == 'week') {
        from = now.subtract(Duration(days: now.weekday - 1));
        from = DateTime(from.year, from.month, from.day);
        to = now;
      } else if (_periodFilter == 'month') {
        from = DateTime(now.year, now.month, 1);
        to = now;
      } else {
        from = null;
        to = null;
      }

      await _reportsProvider.loadReports(forceRefresh: forceRefresh, dateFrom: from, dateTo: to);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat laporan: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _resetPeriodFilter() {
    setState(() => _periodFilter = 'all');
    _loadReports(forceRefresh: true);
  }

  Future<void> _exportReport(String type, String format) async {
    try {
      final message = await _reportsProvider.exportReport(type, format, period: _periodFilter);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
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
        if (!_reportsProvider.hasLoadedData)
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
                  child: ReportOverviewTab(
                    overview: _reportsProvider.overview,
                    statistics: _reportsProvider.statistics,
                  ),
                ),
                RefreshIndicator(
                  onRefresh: () => _loadReports(forceRefresh: true),
                  child: ReportComplaintsTab(
                    items: _reportsProvider.filteredComplaintItems,
                    provider: _reportsProvider,
                    periodFilter: _periodFilter,
                    onShowAllData: _resetPeriodFilter,
                  ),
                ),
                RefreshIndicator(
                  onRefresh: () => _loadReports(forceRefresh: true),
                  child: ReportUsersTab(
                    items: _reportsProvider.filteredUserItems,
                    provider: _reportsProvider,
                    periodFilter: _periodFilter,
                    onShowAllData: _resetPeriodFilter,
                  ),
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
    final fmt = DateFormat('d MMM', 'id_ID');

    String dateLabel;
    if (_periodFilter == 'week') {
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      dateLabel = '${fmt.format(weekStart)} – ${fmt.format(weekEnd)} ${weekEnd.year}';
    } else if (_periodFilter == 'month') {
      dateLabel = DateFormat('MMMM yyyy', 'id_ID').format(now);
    } else {
      dateLabel = 'Semua Data';
    }

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
                value: _periodFilter,
                style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textPrimary),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                items: [
                  DropdownMenuItem(value: 'week', child: Text('Minggu Ini', style: GoogleFonts.nunito(fontSize: 13))),
                  DropdownMenuItem(value: 'month', child: Text('Bulan Ini', style: GoogleFonts.nunito(fontSize: 13))),
                  DropdownMenuItem(value: 'all', child: Text('Semua', style: GoogleFonts.nunito(fontSize: 13))),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _periodFilter = value);
                  _loadReports(forceRefresh: true);
                },
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
}
