import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import 'add_category_screen.dart';
import 'category_detail_screen.dart';
import 'edit_category_screen.dart';

class AdminCategoriesTab extends StatefulWidget {
  const AdminCategoriesTab({super.key});

  @override
  State<AdminCategoriesTab> createState() => _AdminCategoriesTabState();
}

class _AdminCategoriesTabState extends State<AdminCategoriesTab>
    with AutomaticKeepAliveClientMixin {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  // Static caches — raw (unfiltered) and display list
  static bool _hasLoadedDataGlobally = false;
  static List<dynamic> _rawCategories = [];

  List<dynamic> _categories = [];
  bool _hasLoadedData = false;
  String? _selectedStatus;
  String _searchQuery = '';
  final Set<int> _selectedIds = <int>{};

  bool _hasLoadedOnce = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (_hasLoadedDataGlobally && _rawCategories.isNotEmpty) {
      _categories = _applyFilters(_rawCategories);
      _hasLoadedData = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_hasLoadedDataGlobally) _loadCategories();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _applyFilters(List<dynamic> all) {
    return all.where((cat) {
      if (_searchQuery.isNotEmpty) {
        final name = cat['name']?.toString().toLowerCase() ?? '';
        final desc = cat['description']?.toString().toLowerCase() ?? '';
        final q = _searchQuery.toLowerCase();
        if (!name.contains(q) && !desc.contains(q)) return false;
      }
      if (_selectedStatus != null) {
        final active = _toBool(cat['is_active']);
        if (_selectedStatus == 'active' && !active) return false;
        if (_selectedStatus == 'inactive' && active) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _loadCategories({bool forceRefresh = false}) async {
    if (_hasLoadedDataGlobally && !forceRefresh) return;
    try {
      final all = await _adminService.getCategories();
      if (!mounted) return;
      setState(() {
        _rawCategories = all;
        _categories = _applyFilters(all);
        _hasLoadedDataGlobally = true;
        _hasLoadedData = true;
        final available = _categories
            .map((c) => _toInt((c as Map)['id']))
            .where((id) => id > 0)
            .toSet();
        _selectedIds.removeWhere((id) => !available.contains(id));
      });
    } catch (e) {
      if (mounted && forceRefresh) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleStatus(int id) async {
    try {
      await _adminService.toggleCategoryStatus(id);
      await _loadCategories(forceRefresh: true);
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

  Future<void> _deleteCategory(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus kategori ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _adminService.deleteCategory(id);
      await _loadCategories(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori berhasil dihapus'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _bulkAction(String action) async {
    if (_selectedIds.isEmpty) return;
    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus Massal'),
          content: Text('Hapus ${_selectedIds.length} kategori sekaligus? Tindakan ini tidak dapat dibatalkan.'),
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
    }
    try {
      await _adminService.bulkActionCategories(ids: _selectedIds.toList(), action: action);
      await _loadCategories(forceRefresh: true);
      if (!mounted) return;
      setState(() => _selectedIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil dijalankan'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final visibleIds = _categories
        .map((c) => _toInt((c as Map)['id']))
        .where((id) => id > 0)
        .toSet();
    final selectedCount = _selectedIds.where(visibleIds.contains).length;
    final allSelected = visibleIds.isNotEmpty && selectedCount == visibleIds.length;

    return Column(
      children: [
        // ── Search + Filter + Tambah ───────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.nunito(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Cari kategori...',
                    hintStyle: GoogleFonts.nunito(fontSize: 14, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _categories = _applyFilters(_rawCategories);
                              });
                            })
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                  ),
                  onChanged: (v) => setState(() {
                    _searchQuery = v;
                    _categories = _applyFilters(_rawCategories);
                  }),
                ),
              ),
              const SizedBox(width: 8),
              // Filter status
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: _selectedStatus != null ? AppTheme.primary : AppTheme.border),
                  borderRadius: BorderRadius.circular(10),
                  color: _selectedStatus != null ? AppTheme.primary.withValues(alpha: 0.06) : Colors.grey.shade50,
                ),
                child: PopupMenuButton<String>(
                  tooltip: 'Filter Status',
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.filter_list, size: 20, color: _selectedStatus != null ? AppTheme.primary : Colors.grey.shade600),
                  onSelected: (v) => setState(() {
                    _selectedStatus = v == 'all' ? null : v;
                    _categories = _applyFilters(_rawCategories);
                  }),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'all', child: Text('Semua Status')),
                    PopupMenuItem(value: 'active', child: Text('Aktif')),
                    PopupMenuItem(value: 'inactive', child: Text('Nonaktif')),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
                  );
                  if (result == true) _loadCategories(forceRefresh: true);
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text('Tambah', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
              ),
            ],
          ),
        ),

        // ── Active filter chip ────────────────────────────────
        if (_selectedStatus != null)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                ActionChip(
                  label: Text(
                    'Status: ${_selectedStatus == "active" ? "Aktif" : "Nonaktif"}',
                    style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                  avatar: const Icon(Icons.close, size: 14, color: AppTheme.primary),
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                  side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                  onPressed: () => setState(() {
                    _selectedStatus = null;
                    _categories = _applyFilters(_rawCategories);
                  }),
                ),
              ],
            ),
          ),

        // ── Bulk action bar ───────────────────────────────────
        if (_selectedIds.isNotEmpty)
          Container(
            color: AppTheme.primary.withValues(alpha: 0.05),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: allSelected,
                    onChanged: (_) => setState(() {
                      if (allSelected) {
                        _selectedIds.removeWhere(visibleIds.contains);
                      } else {
                        _selectedIds.addAll(visibleIds);
                      }
                    }),
                    activeColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$selectedCount dipilih',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 13),
                ),
                const Spacer(),
                _buildBulkBtn('Aktif', Colors.green, Icons.check_circle_outline, () => _bulkAction('activate')),
                const SizedBox(width: 6),
                _buildBulkBtn('Nonaktif', Colors.orange, Icons.cancel_outlined, () => _bulkAction('deactivate')),
                const SizedBox(width: 6),
                _buildBulkBtn('Hapus', Colors.red, Icons.delete_outline, () => _bulkAction('delete')),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _selectedIds.clear()),
                  child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

        Divider(height: 1, color: AppTheme.border),

        // ── Categories list ────────────────────────────────────
        Expanded(
          child: !_hasLoadedData && _categories.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category_outlined, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Tidak ada kategori', style: GoogleFonts.nunito(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadCategories(forceRefresh: true),
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: _categories.length,
                        itemBuilder: (_, i) => _buildCategoryCard(_categories[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildBulkBtn(String label, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(dynamic category) {
    final isActive = _toBool(category['is_active']);
    final id = _toInt(category['id']);
    final isSelected = _selectedIds.contains(id);
    final count = category['complaints_count'] ?? 0;
    final icon = category['icon']?.toString() ?? '📝';
    final name = category['name']?.toString() ?? '-';
    final description = category['description']?.toString() ?? '';

    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminCategoryDetailScreen(
              category: Map<String, dynamic>.from(category as Map),
            ),
          ),
        );
        if (changed == true) _loadCategories(forceRefresh: true);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => setState(() {
                  if (isSelected) {
                    _selectedIds.remove(id);
                  } else {
                    _selectedIds.add(id);
                  }
                }),
                activeColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 10),
            // Icon bubble
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _miniChip(
                        isActive ? 'Aktif' : 'Nonaktif',
                        isActive ? AppTheme.primary : Colors.grey,
                        isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      ),
                      const SizedBox(width: 6),
                      _miniChip(
                        '$count keluhan',
                        AppTheme.textSecondary,
                        Icons.report_problem_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // More menu
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditCategoryScreen(category: category)),
                    );
                    if (result == true) _loadCategories(forceRefresh: true);
                    break;
                  case 'toggle':
                    _toggleStatus(id);
                    break;
                  case 'delete':
                    _deleteCategory(id);
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')]),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(children: [
                    Icon(
                      isActive ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
                      size: 16,
                      color: isActive ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus', style: TextStyle(color: Colors.red)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

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
      final s = value.toLowerCase();
      return s == '1' || s == 'true' || s == 'yes' || s == 'aktif';
    }
    return false;
  }
}
