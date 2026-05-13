import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../models/complaint_model.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
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
        final cat = complaint['category'];
        if (cat is Map) {
          final nestedId = _toInt(cat['id']);
          if (categoryId != 0 && nestedId != 0) return nestedId == categoryId;
          final nestedName = cat['name']?.toString().toLowerCase() ?? '';
          return nestedName == (_category['name']?.toString().toLowerCase() ?? '');
        }
        final categoryName = complaint['category_name']?.toString().toLowerCase() ?? '';
        return categoryName == (_category['name']?.toString().toLowerCase() ?? '');
      }).toList();

      int pending = 0, inProgress = 0, resolved = 0;
      for (final c in filtered) {
        final status = c['status']?.toString().toLowerCase() ?? '';
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
      MaterialPageRoute(builder: (_) => EditCategoryScreen(category: _category)),
    );
    if (result == true && mounted) {
      _hasChanges = true;
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteCategory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: const Text('Apakah Anda yakin ingin menghapus kategori ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
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

  Future<void> _toggleStatus() async {
    final id = _toInt(_category['id']);
    if (id == 0) return;
    try {
      await _adminService.toggleCategoryStatus(id);
      _hasChanges = true;
      setState(() {
        final current = _toBool(_category['is_active']);
        _category['is_active'] = !current;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status berhasil diubah'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ubah status: $e'), backgroundColor: Colors.red),
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
    final colorName = _category['color']?.toString() ?? _category['theme_color']?.toString() ?? '-';
    final isActive = _toBool(_category['is_active']);
    final latestComplaint = _complaints.isNotEmpty ? _complaints.first : null;

    // Creator & updater info dari API
    final creatorName = _extractUserName(_category['user']);
    final updaterName = _extractUserName(_category['updated_by'] is Map
        ? _category['updated_by']
        : _category['updated_by_user']);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.category_rounded, size: 20),
            const SizedBox(width: 8),
            Text('Detail Kategori', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context, _hasChanges),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero banner ──────────────────────────────
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppTheme.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        left: 20,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(iconEmoji, style: const TextStyle(fontSize: 38)),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 16,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.9),
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: Colors.transparent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: _editCategory,
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: Text('Edit', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 55),

                  // ── Name + badges ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildBadge(
                              isActive ? 'Aktif' : 'Nonaktif',
                              isActive ? AppTheme.primary : Colors.grey,
                              isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            ),
                            if (colorName != '-')
                              _buildBadge(colorName, AppTheme.textSecondary, Icons.palette_outlined),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: GoogleFonts.nunito(color: AppTheme.textSecondary, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Stats ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final cols = w < 620 ? 2 : 4;
                            final itemW = (w - 10.0 * (cols - 1)) / cols;
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                SizedBox(width: itemW, child: _buildStatCard('Total', '${_complaints.length}', Icons.report_problem_outlined, AppTheme.primary)),
                                SizedBox(width: itemW, child: _buildStatCard('Pending', '$_pendingCount', Icons.pending_actions_rounded, AppTheme.warning)),
                                SizedBox(width: itemW, child: _buildStatCard('Dalam Proses', '$_inProgressCount', Icons.autorenew_rounded, Colors.blue)),
                                SizedBox(width: itemW, child: _buildStatCard('Selesai', '$_resolvedCount', Icons.task_alt_rounded, Colors.green)),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          'Keluhan Terbaru',
                          icon: Icons.report_problem_outlined,
                          action: TextButton(
                            onPressed: _showAllComplaints,
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                            child: Text('Lihat Semua', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        latestComplaint == null
                            ? _buildEmptyTile('Belum ada keluhan', 'Belum ada keluhan untuk kategori ini.')
                            : _buildComplaintTile(latestComplaint),

                        const SizedBox(height: 24),
                        _buildSectionHeader('Detail Kategori', icon: Icons.info_outline_rounded),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            children: [
                              _detailRow(Icons.category_outlined, 'Nama', categoryName),
                              const Divider(height: 20),
                              _detailRow(Icons.link_rounded, 'Slug', slug),
                              const Divider(height: 20),
                              _detailRow(Icons.palette_outlined, 'Warna', colorName),
                              const Divider(height: 20),
                              _detailRow(Icons.calendar_today_outlined, 'Dibuat', _formatDate(_category['created_at'])),
                              const Divider(height: 20),
                              _detailRow(Icons.update_rounded, 'Diperbarui', _formatDate(_category['updated_at'])),
                              if (creatorName != '-') ...[
                                const Divider(height: 20),
                                _detailRow(Icons.person_outline_rounded, 'Dibuat oleh', creatorName),
                              ],
                              if (updaterName != '-') ...[
                                const Divider(height: 20),
                                _detailRow(Icons.edit_outlined, 'Diperbarui oleh', updaterName),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        _buildSectionHeader('Aksi', icon: Icons.touch_app_rounded),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _editCategory,
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: Text('Edit Kategori', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _toggleStatus,
                              icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 18),
                              label: Text(isActive ? 'Nonaktifkan' : 'Aktifkan', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isActive ? Colors.orange : AppTheme.primary,
                                side: BorderSide(color: isActive ? Colors.orange : AppTheme.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _showAllComplaints,
                              icon: const Icon(Icons.list_alt_rounded, size: 18),
                              label: Text('Semua Keluhan', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary,
                                side: BorderSide(color: AppTheme.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _deleteCategory,
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              label: Text('Hapus', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
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
            ),
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

  Widget _buildSectionHeader(String title, {Widget? action, IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primary),
          ),
          const SizedBox(width: 8),
        ],
        Text(title, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const Spacer(),
        if (action != null) action,
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(title, style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.textSecondary)),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 32, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildComplaintTile(Map<String, dynamic> complaint) {
    final status = complaint['status']?.toString() ?? 'pending';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        try {
          final model = Complaint.fromJson(complaint);
          await Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaint: model)));
        } catch (_) {}
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
                _buildBadge(_statusText(status), _statusColor(status), Icons.info_outline_rounded),
                const Spacer(),
                Text(_timeAgo(complaint['created_at']), style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
              Text(value, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Pending';
      case 'processing': case 'in_progress': return 'Dalam Proses';
      case 'resolved': case 'completed': return 'Selesai';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'processing': case 'in_progress': return Colors.blue;
      case 'resolved': case 'completed': return Colors.green;
      default: return Colors.grey;
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
      final s = value.toLowerCase();
      return s == '1' || s == 'true' || s == 'yes' || s == 'aktif';
    }
    return false;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _extractUserName(dynamic userObj) {
    if (userObj is Map) return userObj['name']?.toString() ?? '-';
    return '-';
  }
}

// ─── Halaman semua keluhan ──────────────────────────────────────────────────

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
      final s = c['status']?.toString().toLowerCase() ?? '';
      return s == 'pending';
    }).toList();
    final inProgress = complaints.where((c) {
      final s = c['status']?.toString().toLowerCase() ?? '';
      return s == 'processing' || s == 'in_progress';
    }).toList();
    final resolved = complaints.where((c) {
      final s = c['status']?.toString().toLowerCase() ?? '';
      return s == 'resolved' || s == 'completed';
    }).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: Text('Keluhan — $categoryName', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          bottom: TabBar(
            isScrollable: true,
            labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.nunito(fontSize: 13),
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: [
              Tab(text: 'Semua (${complaints.length})'),
              Tab(text: 'Pending (${pending.length})'),
              Tab(text: 'Proses (${inProgress.length})'),
              Tab(text: 'Selesai (${resolved.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(context, complaints),
            _buildList(context, pending),
            _buildList(context, inProgress),
            _buildList(context, resolved),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Belum ada keluhan', style: GoogleFonts.nunito(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final complaint = items[i];
        final status = complaint['status']?.toString() ?? '-';
        final color = _statusColor(status);
        final label = _statusLabel(status);

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            try {
              final model = Complaint.fromJson(complaint);
              await Navigator.push(ctx, MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaint: model)));
            } catch (_) {}
          },
          child: Container(
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
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(label, style: GoogleFonts.nunito(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    Text(
                      complaint['created_at'] != null
                          ? DateFormat('d MMM y').format(DateTime.parse(complaint['created_at'].toString()).toLocal())
                          : '-',
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
  }

  Color _statusColor(String s) {
    final n = s.toLowerCase();
    if (n == 'pending') return Colors.orange;
    if (n == 'processing' || n == 'in_progress') return Colors.blue;
    if (n == 'resolved' || n == 'completed') return Colors.green;
    return Colors.grey;
  }

  String _statusLabel(String s) {
    final n = s.toLowerCase();
    if (n == 'pending') return 'Pending';
    if (n == 'processing' || n == 'in_progress') return 'Dalam Proses';
    if (n == 'resolved' || n == 'completed') return 'Selesai';
    return s;
  }
}
