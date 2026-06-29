import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_router.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/admin_confirm_dialog.dart';
import 'category_detail_utils.dart';
import 'widgets/category_complaint_tile.dart';
import 'widgets/category_detail_widgets.dart';

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
    final categoryId = categoryToInt(_category['id']);
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
        final complaintCategoryId = categoryToInt(complaint['category_id']);
        if (categoryId != 0 && complaintCategoryId != 0) {
          return complaintCategoryId == categoryId;
        }
        final cat = complaint['category'];
        if (cat is Map) {
          final nestedId = categoryToInt(cat['id']);
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
        final ad = parseCategoryDate(a['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = parseCategoryDate(b['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
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
    final result = await context.push(
      AppRouter.adminCategoriesEdit,
      extra: _category,
    );
    if (result == true && mounted) {
      _hasChanges = true;
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteCategory() async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Hapus Kategori',
      message: 'Apakah Anda yakin ingin menghapus kategori ini?',
    );
    if (!confirmed) return;
    try {
      await _adminService.deleteCategory(categoryToInt(_category['id']));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori berhasil dihapus'), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus kategori: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _toggleStatus() async {
    final id = categoryToInt(_category['id']);
    if (id == 0) return;
    try {
      await _adminService.toggleCategoryStatus(id);
      _hasChanges = true;
      setState(() {
        final current = categoryToBool(_category['is_active']);
        _category['is_active'] = !current;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status berhasil diubah'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ubah status: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _showAllComplaints() async {
    await context.push(
      AppRouter.adminCategoryComplaints,
      extra: {
        'categoryName': _category['name']?.toString() ?? 'Kategori',
        'complaints': _complaints,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = _category['name']?.toString() ?? '-';
    final description = _category['description']?.toString() ?? '-';
    final slug = _category['slug']?.toString() ?? '-';
    final iconEmoji = _category['icon']?.toString() ?? '📝';
    final colorName = _category['color']?.toString() ?? _category['theme_color']?.toString() ?? '-';
    final isActive = categoryToBool(_category['is_active']);
    final latestComplaint = _complaints.isNotEmpty ? _complaints.first : null;

    // Creator & updater info dari API
    final creatorName = extractCategoryUserName(_category['user']);
    final updaterName = extractCategoryUserName(
        _category['updated_by'] is Map ? _category['updated_by'] : _category['updated_by_user']);

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
                            CategoryDetailBadge(
                              label: isActive ? 'Aktif' : 'Nonaktif',
                              color: isActive ? AppTheme.primary : Colors.grey,
                              icon: isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            ),
                            if (colorName != '-')
                              CategoryDetailBadge(label: colorName, color: AppTheme.textSecondary, icon: Icons.palette_outlined),
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
                                SizedBox(
                                    width: itemW,
                                    child: CategoryDetailStatCard(
                                        title: 'Total', value: '${_complaints.length}', icon: Icons.report_problem_outlined, color: AppTheme.primary)),
                                SizedBox(
                                    width: itemW,
                                    child: CategoryDetailStatCard(
                                        title: 'Pending', value: '$_pendingCount', icon: Icons.pending_actions_rounded, color: AppTheme.warning)),
                                SizedBox(
                                    width: itemW,
                                    child: CategoryDetailStatCard(
                                        title: 'Dalam Proses', value: '$_inProgressCount', icon: Icons.autorenew_rounded, color: AppTheme.info)),
                                SizedBox(
                                    width: itemW,
                                    child: CategoryDetailStatCard(
                                        title: 'Selesai', value: '$_resolvedCount', icon: Icons.task_alt_rounded, color: AppTheme.success)),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),
                        CategoryDetailSectionHeader(
                          title: 'Keluhan Terbaru',
                          icon: Icons.report_problem_outlined,
                          action: TextButton(
                            onPressed: _showAllComplaints,
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                            child: Text('Lihat Semua', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        latestComplaint == null
                            ? const CategoryDetailEmptyTile(title: 'Belum ada keluhan', subtitle: 'Belum ada keluhan untuk kategori ini.')
                            : CategoryComplaintTile(complaint: latestComplaint),

                        const SizedBox(height: 24),
                        const CategoryDetailSectionHeader(title: 'Detail Kategori', icon: Icons.info_outline_rounded),
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
                              CategoryDetailRow(icon: Icons.category_outlined, label: 'Nama', value: categoryName),
                              const Divider(height: 20),
                              CategoryDetailRow(icon: Icons.link_rounded, label: 'Slug', value: slug),
                              const Divider(height: 20),
                              CategoryDetailRow(icon: Icons.palette_outlined, label: 'Warna', value: colorName),
                              const Divider(height: 20),
                              CategoryDetailRow(icon: Icons.calendar_today_outlined, label: 'Dibuat', value: formatCategoryDate(_category['created_at'])),
                              const Divider(height: 20),
                              CategoryDetailRow(icon: Icons.update_rounded, label: 'Diperbarui', value: formatCategoryDate(_category['updated_at'])),
                              if (creatorName != '-') ...[
                                const Divider(height: 20),
                                CategoryDetailRow(icon: Icons.person_outline_rounded, label: 'Dibuat oleh', value: creatorName),
                              ],
                              if (updaterName != '-') ...[
                                const Divider(height: 20),
                                CategoryDetailRow(icon: Icons.edit_outlined, label: 'Diperbarui oleh', value: updaterName),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        const CategoryDetailSectionHeader(title: 'Aksi', icon: Icons.touch_app_rounded),
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
                                foregroundColor: isActive ? AppTheme.warning : AppTheme.primary,
                                side: BorderSide(color: isActive ? AppTheme.warning : AppTheme.primary),
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
            ),
    );
  }
}
