import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/complaint_model.dart';
import '../../../services/admin_service.dart';
import '../../complaints/complaint_detail_screen.dart';
import 'edit_category_screen.dart';

class AdminCategoryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> category;

  const AdminCategoryDetailScreen({
    super.key,
    required this.category,
  });

  @override
  State<AdminCategoryDetailScreen> createState() => _AdminCategoryDetailScreenState();
}

class _AdminCategoryDetailScreenState extends State<AdminCategoryDetailScreen> {
  final AdminService _adminService = AdminService();

  late Map<String, dynamic> _category;
  bool _isLoading = false;
  bool _hasChanges = false;

  List<Map<String, dynamic>> _complaints = [];
  int _pendingCount = 0;
  int _inProgressCount = 0;
  int _resolvedCount = 0;

  @override
  void initState() {
    super.initState();
    _category = Map<String, dynamic>.from(widget.category);
    _loadCategoryComplaints();
  }

  Future<void> _loadCategoryComplaints() async {
    final categoryId = _toInt(_category['id']);
    setState(() => _isLoading = true);

    try {
      final response = await _adminService.getComplaints(
        perPage: 100,
        categoryId: categoryId == 0 ? null : categoryId,
        search: categoryId == 0 ? _category['name']?.toString() : null,
      );

      final raw = (response['data'] as List?) ?? const [];
      final all = raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();

      final filtered = all.where((complaint) {
        final complaintCategoryId = _toInt(complaint['category_id']);
        if (categoryId != 0 && complaintCategoryId != 0) {
          return complaintCategoryId == categoryId;
        }

        final category = complaint['category'];
        if (category is Map) {
          final nestedId = _toInt(category['id']);
          if (categoryId != 0 && nestedId != 0) return nestedId == categoryId;
          final nestedName = category['name']?.toString().toLowerCase() ?? '';
          return nestedName == (_category['name']?.toString().toLowerCase() ?? '');
        }

        final categoryName = complaint['category_name']?.toString().toLowerCase() ?? '';
        return categoryName == (_category['name']?.toString().toLowerCase() ?? '');
      }).toList();

      int pending = 0;
      int inProgress = 0;
      int resolved = 0;

      for (final complaint in filtered) {
        final status = complaint['status']?.toString().toLowerCase() ?? '';
        if (status == 'pending') {
          pending++;
        } else if (status == 'processing' || status == 'in_progress') {
          inProgress++;
        } else if (status == 'resolved' || status == 'completed') {
          resolved++;
        }
      }

      filtered.sort((a, b) {
        final ad = _parseDate(a['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = _parseDate(b['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      if (!mounted) return;
      setState(() {
        _complaints = filtered;
        _pendingCount = pending;
        _inProgressCount = inProgress;
        _resolvedCount = resolved;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditCategoryScreen(category: _category),
      ),
    );

    if (result == true && mounted) {
      _hasChanges = true;
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteCategory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: const Text('Apakah Anda yakin ingin menghapus kategori ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminService.deleteCategory(_toInt(_category['id']));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori berhasil dihapus'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus kategori: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showAllComplaints() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CategoryComplaintsScreen(
          categoryName: _category['name']?.toString() ?? 'Kategori',
          complaints: _complaints,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = _category['name']?.toString() ?? '-';
    final description = _category['description']?.toString() ?? '-';
    final slug = _category['slug']?.toString() ?? '-';
    final iconEmoji = _category['icon']?.toString() ?? '📝';
    final iconName = _category['icon_name']?.toString() ?? 'Building-2';
    final colorName = _category['color']?.toString() ?? _category['theme_color']?.toString() ?? 'Purple';
    final isActive = _toBool(_category['is_active']);
    final totalComplaints = _complaints.length;
    final latestComplaint = _complaints.isNotEmpty ? _complaints.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kategori'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _hasChanges),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(iconEmoji, style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 8),
                  Text(
                    categoryName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(isActive ? 'Aktif' : 'Nonaktif', isActive ? Colors.green : Colors.grey, isActive ? Icons.check_circle : Icons.cancel),
                      _chip(colorName, Colors.purple, Icons.palette),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(description),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _editCategory,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context, _hasChanges),
                        child: const Text('Kembali'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _statCard('Total Keluhan', '$totalComplaints', Icons.report_problem_outlined),
                      _statCard('Pending', '$_pendingCount', Icons.pending_actions),
                      _statCard('Dalam Proses', '$_inProgressCount', Icons.autorenew),
                      _statCard('Selesai', '$_resolvedCount', Icons.task_alt),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sectionHeader(
                    'Keluhan Terbaru',
                    action: TextButton(
                      onPressed: _showAllComplaints,
                      child: const Text('Lihat Semua'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (latestComplaint == null)
                    _emptyTile(
                      'Belum ada keluhan',
                      'Belum ada keluhan yang masuk untuk kategori ini.',
                    )
                  else
                    _complaintTile(latestComplaint),
                  const SizedBox(height: 18),
                  _sectionHeader('Detail Kategori'),
                  const SizedBox(height: 8),
                  _detailRow('Nama', categoryName),
                  _detailRow('Slug', slug),
                  _detailRow('Deskripsi', description),
                  _detailRow('Icon', '$iconEmoji\n$iconName'),
                  _detailRow('Warna Theme', colorName),
                  _detailRow('Status', isActive ? 'Aktif' : 'Nonaktif'),
                  _detailRow('Dibuat', _formatDate(_category['created_at'])),
                  _detailRow('Terakhir Update', _formatDate(_category['updated_at'])),
                  const SizedBox(height: 18),
                  _sectionHeader('Aksi'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _editCategory,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Kategori'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _showAllComplaints,
                        icon: const Icon(Icons.list_alt),
                        label: const Text('Lihat Semua Keluhan'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _deleteCategory,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Hapus Kategori', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title, {Widget? action}) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (action != null) action,
      ],
    );
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyTile(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _complaintTile(Map<String, dynamic> complaint) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        try {
          final complaintModel = Complaint.fromJson(complaint);
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaint: complaintModel)),
          );
        } catch (_) {}
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              complaint['title']?.toString() ?? complaint['description']?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '${_formatStatus(complaint['status'])} • ${_timeAgo(complaint['created_at'])}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: Colors.grey.shade700))),
          const Text(': '),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  String _formatStatus(dynamic value) {
    final status = value?.toString().toLowerCase() ?? 'pending';
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
      case 'in_progress':
        return 'Dalam Proses';
      case 'resolved':
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  String _timeAgo(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return '-';

    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('d MMM y').format(date);
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return '-';
    return DateFormat('d MMMM y, HH:mm').format(date);
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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class _CategoryComplaintsScreen extends StatelessWidget {
  final String categoryName;
  final List<Map<String, dynamic>> complaints;

  const _CategoryComplaintsScreen({
    required this.categoryName,
    required this.complaints,
  });

  @override
  Widget build(BuildContext context) {
    final pending = complaints.where((c) {
      final status = c['status']?.toString().toLowerCase() ?? '';
      return status == 'pending';
    }).toList();

    final inProgress = complaints.where((c) {
      final status = c['status']?.toString().toLowerCase() ?? '';
      return status == 'processing' || status == 'in_progress';
    }).toList();

    final resolved = complaints.where((c) {
      final status = c['status']?.toString().toLowerCase() ?? '';
      return status == 'resolved' || status == 'completed';
    }).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Keluhan - $categoryName'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Semua (${complaints.length})'),
              Tab(text: 'Pending (${pending.length})'),
              Tab(text: 'Dalam Proses (${inProgress.length})'),
              Tab(text: 'Selesai (${resolved.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildComplaintsList(context, complaints),
            _buildComplaintsList(context, pending),
            _buildComplaintsList(context, inProgress),
            _buildComplaintsList(context, resolved),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintsList(BuildContext context, List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Belum ada keluhan di status ini.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final complaint = items[index];
        final status = complaint['status']?.toString() ?? '-';
        final statusColor = _statusColor(status);
        final statusLabel = _statusLabel(status);

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            try {
              final complaintModel = Complaint.fromJson(complaint);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaint: complaintModel)),
              );
            } catch (_) {}
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint['title']?.toString() ?? complaint['description']?.toString() ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        complaint['created_at'] != null
                            ? DateFormat('d MMM y, HH:mm').format(DateTime.parse(complaint['created_at'].toString()).toLocal())
                            : '-',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'pending') return Colors.orange;
    if (normalized == 'processing' || normalized == 'in_progress') return Colors.blue;
    if (normalized == 'resolved' || normalized == 'completed') return Colors.green;
    return Colors.grey;
  }

  String _statusLabel(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'pending') return 'Pending';
    if (normalized == 'processing' || normalized == 'in_progress') return 'Dalam Progress';
    if (normalized == 'resolved' || normalized == 'completed') return 'Selesai';
    return status;
  }
}
