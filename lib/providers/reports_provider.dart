import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../services/reports_service.dart';

class ReportsProvider extends ChangeNotifier {
  final ReportsService _reportsService = ReportsService();
  final Set<int> _selectedComplaintIds = <int>{};

  // Cache statis — simpan parsed items agar tidak re-fetch setiap navigate
  static bool _hasLoadedDataGlobally = false;
  static Map<String, dynamic>? _cachedOverview;
  static Map<String, dynamic>? _cachedStatistics;
  static List<Map<String, dynamic>> _cachedComplaintItems = [];
  static List<Map<String, dynamic>> _cachedUserItems = [];

  Map<String, dynamic>? overview;
  Map<String, dynamic>? statistics;

  List<Map<String, dynamic>> complaintItems = [];
  List<Map<String, dynamic>> filteredComplaintItems = [];
  List<Map<String, dynamic>> userItems = [];
  List<Map<String, dynamic>> filteredUserItems = [];

  DateTime? complaintFromDate;
  DateTime? complaintToDate;
  String complaintStatusFilter = 'all';
  String complaintCategoryFilter = 'all';

  DateTime? userFromDate;
  DateTime? userToDate;
  String userStatusFilter = 'all';
  String userSearchQuery = '';

  bool hasLoadedData = false;

  int get selectedComplaintCount => _selectedComplaintIds.length;
  bool get hasSelectedComplaints => _selectedComplaintIds.isNotEmpty;

  ReportsProvider() {
    // Tanpa batasan tanggal default — tampilkan semua data
    complaintFromDate = null;
    complaintToDate = null;
    userFromDate = null;
    userToDate = null;

    if (_hasLoadedDataGlobally && _cachedComplaintItems.isNotEmpty) {
      overview = _cachedOverview;
      statistics = _cachedStatistics;
      complaintItems = List.of(_cachedComplaintItems);
      userItems = List.of(_cachedUserItems);
      _applyComplaintFilterLocal();
      _applyUserFilterLocal();
      hasLoadedData = true;
    } else {
      // Reset agar data di-fetch ulang
      _hasLoadedDataGlobally = false;
    }
  }

  Future<void> loadReports({
    bool forceRefresh = false,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    if (_hasLoadedDataGlobally && !forceRefresh) return;

    final dateFromStr =
        dateFrom != null ? DateFormat('yyyy-MM-dd').format(dateFrom) : null;
    final dateToStr =
        dateTo != null ? DateFormat('yyyy-MM-dd').format(dateTo) : null;

    final payload = await _reportsService.fetchReportsData(
      dateFrom: dateFromStr,
      dateTo: dateToStr,
    );

    overview = payload['overview'] as Map<String, dynamic>?;
    statistics = payload['statistics'] as Map<String, dynamic>?;

    // Items sudah di-flatten oleh _fetchAllPages di service
    final rawComplaints = payload['complaintItems'];
    final rawUsers = payload['userItems'];

    complaintItems = (rawComplaints is List ? rawComplaints : <dynamic>[])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((item) => item['deleted_at'] == null)
        .toList();

    userItems = (rawUsers is List ? rawUsers : <dynamic>[])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // Simpan ke cache
    _cachedOverview = overview;
    _cachedStatistics = statistics;
    _cachedComplaintItems = List.of(complaintItems);
    _cachedUserItems = List.of(userItems);
    _hasLoadedDataGlobally = true;

    _applyComplaintFilterLocal();
    _applyUserFilterLocal();
    hasLoadedData = true;
    notifyListeners();
  }

  void _applyComplaintFilterLocal() {
    filteredComplaintItems = complaintItems.where((item) {
      final created = _parseDate(item['created_at']);
      final from = complaintFromDate;
      final to = complaintToDate;

      if (from != null &&
          created != null &&
          created.isBefore(DateTime(from.year, from.month, from.day))) {
        return false;
      }
      if (to != null && created != null) {
        final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
        if (created.isAfter(end)) return false;
      }
      if (complaintStatusFilter != 'all') {
        final normalized =
            _normalizeComplaintStatus(item['status']?.toString() ?? '');
        if (normalized != complaintStatusFilter) return false;
      }
      if (complaintCategoryFilter != 'all') {
        final category = _complaintCategoryName(item).toLowerCase();
        if (category != complaintCategoryFilter.toLowerCase()) return false;
      }
      return true;
    }).toList();

    filteredComplaintItems.sort((a, b) {
      final ad =
          _parseDate(a['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd =
          _parseDate(b['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    final availableIds = complaintItems
        .map((item) => _toInt(item['id']))
        .where((id) => id > 0)
        .toSet();
    _selectedComplaintIds.removeWhere((id) => !availableIds.contains(id));
  }

  void _applyUserFilterLocal() {
    final search = userSearchQuery.trim().toLowerCase();

    filteredUserItems = userItems.where((item) {
      final created = _parseDate(item['created_at']);
      final from = userFromDate;
      final to = userToDate;

      if (from != null &&
          created != null &&
          created.isBefore(DateTime(from.year, from.month, from.day))) {
        return false;
      }
      if (to != null && created != null) {
        final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
        if (created.isAfter(end)) return false;
      }
      if (userStatusFilter != 'all') {
        final isActive = _toBool(item['is_active']);
        if (userStatusFilter == 'active' && !isActive) return false;
        if (userStatusFilter == 'inactive' && isActive) return false;
      }
      if (search.isNotEmpty) {
        final name = (item['name']?.toString() ?? '').toLowerCase();
        final email = (item['email']?.toString() ?? '').toLowerCase();
        if (!name.contains(search) && !email.contains(search)) return false;
      }
      return true;
    }).toList();

    filteredUserItems.sort((a, b) {
      final ad =
          _parseDate(a['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd =
          _parseDate(b['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
  }

  Future<String> exportReport(String type, String format,
      {String period = 'all'}) async {
    final exportItems = await _reportsService.fetchExportData(
      type: type,
      period: period,
    );

    if (exportItems.isEmpty) {
      throw Exception('Tidak ada data untuk diekspor');
    }

    final rows = type == 'complaints'
        ? _buildComplaintRowsFromList(exportItems)
        : _buildUserRowsFromList(exportItems);

    return _reportsService.exportReport(
      reportType: type,
      format: format,
      title: _reportTitle(type),
      headers: _buildReportHeaders(type),
      rows: rows,
    );
  }

  bool isComplaintSelected(Map<String, dynamic> complaint) {
    final id = _toInt(complaint['id']);
    return id > 0 && _selectedComplaintIds.contains(id);
  }

  void toggleComplaintSelection(Map<String, dynamic> complaint) {
    final id = _toInt(complaint['id']);
    if (id <= 0) return;
    if (_selectedComplaintIds.contains(id)) {
      _selectedComplaintIds.remove(id);
    } else {
      _selectedComplaintIds.add(id);
    }
    notifyListeners();
  }

  void selectAllFilteredComplaints() {
    for (final complaint in filteredComplaintItems) {
      final id = _toInt(complaint['id']);
      if (id > 0) _selectedComplaintIds.add(id);
    }
    notifyListeners();
  }

  void clearSelectedComplaints() {
    _selectedComplaintIds.clear();
    notifyListeners();
  }

  List<String> allComplaintCategories() {
    final set = <String>{};
    for (final item in complaintItems) {
      final category = _complaintCategoryName(item);
      if (category.trim().isNotEmpty && category != '-') set.add(category);
    }
    return set.toList()..sort();
  }

  String normalizeComplaintStatus(String status) =>
      _normalizeComplaintStatus(status);
  String complaintCategoryName(Map<String, dynamic> c) =>
      _complaintCategoryName(c);

  String complaintUserName(Map<String, dynamic> complaint) {
    final user = complaint['user'];
    if (user is Map) return user['name']?.toString() ?? '-';
    return complaint['user_name']?.toString() ??
        complaint['complainant_name']?.toString() ??
        '-';
  }

  DateTime? parseDate(dynamic value) => _parseDate(value);
  bool toBool(dynamic value) => _toBool(value);
  int toInt(dynamic value) => _toInt(value);

  String firstString(Map<String, dynamic> source, List<String> keys,
      {String fallback = '-'}) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty)
        return value.toString();
    }
    return fallback;
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _reportTitle(String type) {
    switch (type) {
      case 'complaints':
        return 'Laporan Keluhan';
      case 'users':
        return 'Laporan Pengguna';
      default:
        return 'Laporan';
    }
  }

  List<String> _buildReportHeaders(String type) {
    switch (type) {
      case 'complaints':
        return [
          'No',
          'Judul',
          'Status',
          'Kategori',
          'Pelapor',
          'Lokasi',
          'Prioritas',
          'Dibuat'
        ];
      case 'users':
        return [
          'No',
          'Nama',
          'Email',
          'Telepon',
          'Status',
          'Jumlah Keluhan',
          'Bergabung',
          'Verifikasi Email'
        ];
      default:
        return ['No', 'Data'];
    }
  }

  List<List<String>> _buildComplaintRowsFromList(
      List<Map<String, dynamic>> source) {
    return source.asMap().entries.map((entry) {
      final c = entry.value;
      final created = _parseDate(c['created_at']);
      final status = _normalizeComplaintStatus(c['status']?.toString() ?? '');
      return [
        '${entry.key + 1}',
        c['title']?.toString() ?? c['description']?.toString() ?? '-',
        _statusText(status),
        _complaintCategoryName(c),
        complaintUserName(c),
        firstString(c, ['address', 'location', 'full_address'], fallback: '-'),
        firstString(c, ['priority'], fallback: 'Sedang'),
        created == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(created),
      ];
    }).toList();
  }

  List<List<String>> _buildUserRowsFromList(List<Map<String, dynamic>> source) {
    return source.asMap().entries.map((entry) {
      final u = entry.value;
      final created = _parseDate(u['created_at']);
      final emailVerified =
          _toBool(u['is_email_verified']) || u['email_verified_at'] != null;
      return [
        '${entry.key + 1}',
        u['name']?.toString() ?? '-',
        u['email']?.toString() ?? '-',
        u['phone']?.toString() ?? '-',
        _toBool(u['is_active']) ? 'Aktif' : 'Tidak Aktif',
        '${_toInt(u['complaints_count'])}',
        created == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(created),
        emailVerified ? 'Terverifikasi' : 'Belum',
      ];
    }).toList();
  }

  String _complaintCategoryName(Map<String, dynamic> complaint) {
    final category = complaint['category'];
    if (category is Map) return category['name']?.toString() ?? '-';
    return complaint['category_name']?.toString() ??
        complaint['category']?.toString() ??
        '-';
  }

  String _normalizeComplaintStatus(String status) {
    final s = status.toLowerCase();
    if (s == 'processing' || s == 'inprogress') return 'in_progress';
    if (s == 'completed') return 'resolved';
    return s;
  }

  String _statusText(String normalized) {
    switch (normalized) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'Dalam Proses';
      case 'resolved':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return normalized;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final s = value.toLowerCase();
      return s == '1' || s == 'true' || s == 'yes' || s == 'aktif';
    }
    return false;
  }
}
