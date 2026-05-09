import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../services/reports_service.dart';

class ReportsProvider extends ChangeNotifier {
  final ReportsService _reportsService = ReportsService();
  final Set<int> _selectedComplaintIds = <int>{};

  static bool _hasLoadedDataGlobally = false;
  static Map<String, dynamic>? _cachedOverview;
  static Map<String, dynamic>? _cachedComplaintsReport;
  static Map<String, dynamic>? _cachedUsersReport;
  static Map<String, dynamic>? _cachedStatistics;

  Map<String, dynamic>? overview;
  Map<String, dynamic>? complaintsReport;
  Map<String, dynamic>? usersReport;
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
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 31));

    complaintFromDate = monthAgo;
    complaintToDate = now;
    userFromDate = monthAgo;
    userToDate = now;

    if (_hasLoadedDataGlobally && _cachedOverview != null) {
      overview = _cachedOverview;
      complaintsReport = _cachedComplaintsReport;
      usersReport = _cachedUsersReport;
      statistics = _cachedStatistics;
      _hydrateReportLists();
      hasLoadedData = true;
    }
  }

  Future<void> loadReports({bool forceRefresh = false}) async {
    if (_hasLoadedDataGlobally && !forceRefresh) return;

    final payload = await _reportsService.fetchReportsData();

    overview = payload['overview'] as Map<String, dynamic>?;
    statistics = payload['statistics'] as Map<String, dynamic>?;
    complaintsReport = payload['complaintsReport'] as Map<String, dynamic>?;
    usersReport = payload['usersReport'] as Map<String, dynamic>?;

    _cachedOverview = overview;
    _cachedStatistics = statistics;
    _cachedComplaintsReport = complaintsReport;
    _cachedUsersReport = usersReport;
    _hasLoadedDataGlobally = true;

    _hydrateReportLists();
    hasLoadedData = true;
    notifyListeners();
  }

  Future<void> applyComplaintFilter() async {
    final normalizedStatus = complaintStatusFilter == 'all' ? null : complaintStatusFilter;

    try {
      final response = await _reportsService.fetchComplaintsReport(
        dateFrom: complaintFromDate,
        dateTo: complaintToDate,
        status: normalizedStatus,
        categoryId: _selectedCategoryId(),
        perPage: 100,
      );

      complaintsReport = response;
      _cachedComplaintsReport = response;
      complaintItems = _reportsService
          .extractItems(response)
          .where((item) => item['deleted_at'] == null)
          .toList();
    } catch (_) {
      // Fallback to existing in-memory data when remote filtering fails.
    }

    _applyComplaintFilterLocal();
    notifyListeners();
  }

  Future<void> applyUserFilter() async {
    bool? isActive;
    if (userStatusFilter == 'active') isActive = true;
    if (userStatusFilter == 'inactive') isActive = false;

    try {
      final response = await _reportsService.fetchUsersReport(
        dateFrom: userFromDate,
        dateTo: userToDate,
        isActive: isActive,
        search: userSearchQuery,
        perPage: 100,
      );

      usersReport = response;
      _cachedUsersReport = response;
      userItems = _reportsService.extractItems(response);
    } catch (_) {
      // Fallback to existing in-memory data when remote filtering fails.
    }

    _applyUserFilterLocal();
    notifyListeners();
  }

  void _applyComplaintFilterLocal() {
    final from = complaintFromDate;
    final to = complaintToDate;

    filteredComplaintItems = complaintItems.where((item) {
      final created = _parseDate(item['created_at']);

      if (from != null && created != null && created.isBefore(DateTime(from.year, from.month, from.day))) {
        return false;
      }

      if (to != null && created != null) {
        final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
        if (created.isAfter(end)) return false;
      }

      if (complaintStatusFilter != 'all') {
        final normalized = _normalizeComplaintStatus(item['status']?.toString() ?? '');
        if (normalized != complaintStatusFilter) return false;
      }

      if (complaintCategoryFilter != 'all') {
        final category = _complaintCategoryName(item).toLowerCase();
        if (category != complaintCategoryFilter.toLowerCase()) return false;
      }

      return true;
    }).toList();

    filteredComplaintItems.sort((a, b) {
      final ad = _parseDate(a['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = _parseDate(b['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    final availableIds = complaintItems
        .map((item) => _toInt(item['id']))
        .where((id) => id > 0)
        .toSet();
    _selectedComplaintIds.removeWhere((id) => !availableIds.contains(id));

  }

  void _applyUserFilterLocal() {
    final from = userFromDate;
    final to = userToDate;
    final search = userSearchQuery.trim().toLowerCase();

    filteredUserItems = userItems.where((item) {
      final created = _parseDate(item['created_at']);

      if (from != null && created != null && created.isBefore(DateTime(from.year, from.month, from.day))) {
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
      final ad = _parseDate(a['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = _parseDate(b['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

  }

  Future<String> exportReport(String type, String format) async {
    List<Map<String, dynamic>> items;
    try {
      items = await _reportsService.fetchExportData(type: type);
    } catch (_) {
      // Fallback ke data in-memory jika API gagal
      items = type == 'complaints' ? filteredComplaintItems : filteredUserItems;
    }

    final List<List<String>> rows = type == 'complaints'
        ? _buildComplaintRowsFromList(items)
        : _buildUserRowsFromList(items);
    final title = _reportTitle(type);
    final headers = _buildReportHeaders(type);
    return _reportsService.exportReport(
      reportType: type,
      format: format,
      title: title,
      headers: headers,
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
      if (id > 0) {
        _selectedComplaintIds.add(id);
      }
    }
    notifyListeners();
  }

  void clearSelectedComplaints() {
    _selectedComplaintIds.clear();
    notifyListeners();
  }

  Future<String> exportSelectedComplaints(String format) async {
    final selected = complaintItems.where((item) {
      final id = _toInt(item['id']);
      return id > 0 && _selectedComplaintIds.contains(id);
    }).toList();

    final rows = _buildComplaintRowsFromList(selected);
    return _reportsService.exportReport(
      reportType: 'complaints_selected',
      format: format,
      title: 'Laporan Keluhan Terpilih',
      headers: _buildReportHeaders('complaints'),
      rows: rows,
    );
  }

  Future<String> exportComplaintsByUser({
    required int userId,
    required String userName,
    required String format,
  }) async {
    final complaints = await _reportsService.fetchComplaintsByUser(userId);
    final rows = _buildComplaintRowsFromList(complaints);

    return _reportsService.exportReport(
      reportType: 'complaints_user_$userId',
      format: format,
      title: 'Laporan Keluhan Pengguna - $userName',
      headers: _buildReportHeaders('complaints'),
      rows: rows,
    );
  }

  List<String> allComplaintCategories() {
    final set = <String>{};
    for (final item in complaintItems) {
      final category = _complaintCategoryName(item);
      if (category.trim().isNotEmpty && category != '-') {
        set.add(category);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  String normalizeComplaintStatus(String status) => _normalizeComplaintStatus(status);

  String complaintCategoryName(Map<String, dynamic> complaint) => _complaintCategoryName(complaint);

  String complaintUserName(Map<String, dynamic> complaint) {
    final user = complaint['user'];
    if (user is Map) {
      return user['name']?.toString() ?? '-';
    }
    return complaint['user_name']?.toString() ?? complaint['complainant_name']?.toString() ?? '-';
  }

  DateTime? parseDate(dynamic value) => _parseDate(value);

  String firstString(Map<String, dynamic> source, List<String> keys, {String fallback = '-'}) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString();
    }
    return fallback;
  }

  bool toBool(dynamic value) => _toBool(value);

  int toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  void _hydrateReportLists() {
    // Filter out soft-deleted (trashed) complaints
    complaintItems = _reportsService
        .extractItems(complaintsReport)
        .where((item) => item['deleted_at'] == null)
        .toList();
    userItems = _reportsService.extractItems(usersReport);

    filteredComplaintItems = [];
    filteredUserItems = [];
    _applyComplaintFilterLocal();
    _applyUserFilterLocal();
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
          'Dibuat',
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
          'Login Terakhir',
          'Verifikasi Email',
        ];
      default:
        return ['No', 'Data'];
    }
  }

  List<List<String>> _buildUserRowsFromList(List<Map<String, dynamic>> source) {
    return source.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final user = entry.value;
      final created = _parseDate(user['created_at']);
      final lastLogin = _parseDate(user['last_login_at']);
      final emailVerified = _toBool(user['is_email_verified']) || user['email_verified_at'] != null;

      return [
        '$index',
        user['name']?.toString() ?? '-',
        user['email']?.toString() ?? '-',
        user['phone']?.toString() ?? '-',
        _toBool(user['is_active']) ? 'Aktif' : 'Tidak Aktif',
        '${toInt(user['complaints_count'])}',
        created == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(created),
        lastLogin == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(lastLogin),
        emailVerified ? 'Terverifikasi' : 'Belum',
      ];
    }).toList();
  }

  List<List<String>> _buildComplaintRowsFromList(List<Map<String, dynamic>> source) {
    return source.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final complaint = entry.value;
      final created = _parseDate(complaint['created_at']);
      final normalizedStatus = _normalizeComplaintStatus(
        complaint['status']?.toString() ?? '',
      );

      return [
        '$index',
        complaint['title']?.toString() ?? complaint['description']?.toString() ?? '-',
        _statusText(normalizedStatus),
        _complaintCategoryName(complaint),
        complaintUserName(complaint),
        firstString(complaint, ['address', 'location', 'full_address'], fallback: '-'),
        firstString(complaint, ['priority'], fallback: 'Sedang'),
        created == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(created),
      ];
    }).toList();
  }

  String _complaintCategoryName(Map<String, dynamic> complaint) {
    final category = complaint['category'];
    if (category is Map) {
      return category['name']?.toString() ?? '-';
    }
    return complaint['category_name']?.toString() ?? complaint['category']?.toString() ?? '-';
  }

  int? _selectedCategoryId() {
    if (complaintCategoryFilter == 'all') return null;

    final selected = complaintCategoryFilter.toLowerCase();
    for (final item in complaintItems) {
      final name = _complaintCategoryName(item).toLowerCase();
      if (name != selected) continue;

      final category = item['category'];
      if (category is Map) {
        final id = _toInt(category['id']);
        if (id > 0) return id;
      }

      final id = _toInt(item['category_id']);
      if (id > 0) return id;
    }

    return null;
  }

  String _normalizeComplaintStatus(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'processing' || normalized == 'inprogress') return 'in_progress';
    if (normalized == 'completed') return 'resolved';
    return normalized;
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

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == '1' || normalized == 'true' || normalized == 'yes' || normalized == 'aktif';
    }
    return false;
  }
}
