import 'package:flutter/material.dart';
import 'package:mypengaduan_app/widgets/admin/admin_status_badge.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/admin_filter_panel.dart';
import '../../../widgets/admin/admin_empty_state.dart';
import '../../../widgets/admin/admin_info_card.dart';
import '../../../widgets/admin/admin_section_header.dart';
import '../../../widgets/skeleton_loader.dart';
import 'category_detail_screen.dart';
import 'edit_category_screen.dart';


class AdminCategoriesTab extends StatefulWidget {
  const AdminCategoriesTab({super.key});

  @override
  State<AdminCategoriesTab> createState() => _AdminCategoriesTabState();

  void reload() {
    // Access state to reload
  }
}

class _AdminCategoriesTabState extends State<AdminCategoriesTab> with AutomaticKeepAliveClientMixin {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  
  // Static cache for global state persistence
  static bool _hasLoadedDataGlobally = false;
  static List<dynamic> _cachedCategories = [];
  
  List<dynamic> _categories = [];
  bool _hasLoadedData = false;
  String? _selectedStatus;
  String _searchQuery = '';
  final Set<int> _selectedCategoryIds = <int>{};
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint('📑 [AdminCategoriesTab] Screen initialized - will load after visible');
    
    // Use cached data if available
    if (_hasLoadedDataGlobally && _cachedCategories.isNotEmpty) {
      debugPrint('📑 [AdminCategoriesTab] Using cached data (${_cachedCategories.length} items)');
      _categories = _cachedCategories;
      _hasLoadedData = true;
    }
  }

  bool _hasLoadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load only once when screen becomes visible
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_hasLoadedDataGlobally) {
          debugPrint('📑 [AdminCategoriesTab] Screen visible - loading categories now');
          _loadCategories();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories({bool forceRefresh = false}) async {
    // Skip loading if already loaded globally and not forcing refresh
    if (_hasLoadedDataGlobally && !forceRefresh) {
      debugPrint('Admin Categories: Already loaded globally, skipping...');
      return;
    }
    
    debugPrint('Admin Categories: Loading categories... (forceRefresh: $forceRefresh)');
    try {
      final categories = await _adminService.getCategories();
      
      if (mounted) {
        setState(() {
          // Filter by search query
          _categories = categories.where((cat) {
            if (_searchQuery.isNotEmpty) {
              final name = cat['name']?.toString().toLowerCase() ?? '';
              final description = cat['description']?.toString().toLowerCase() ?? '';
              final query = _searchQuery.toLowerCase();
              if (!name.contains(query) && !description.contains(query)) {
                return false;
              }
            }
            
            // Filter by status
            if (_selectedStatus != null) {
              final isActive = cat['is_active'] == true || cat['is_active'] == 1;
              if (_selectedStatus == 'active' && !isActive) return false;
              if (_selectedStatus == 'inactive' && isActive) return false;
            }
            
            return true;
          }).toList();
          
          _cachedCategories = _categories; // Update cache
          _hasLoadedDataGlobally = true; // Mark as loaded globally
          _hasLoadedData = true;
          final availableIds = _categories
              .map((cat) => _toInt((cat as Map)['id']))
              .where((id) => id > 0)
              .toSet();
          _selectedCategoryIds.removeWhere((id) => !availableIds.contains(id));
        });
      }
    } catch (e) {
      if (mounted && forceRefresh) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleStatus(int id) async {
    try {
      await _adminService.toggleCategoryStatus(id);
      _loadCategories();
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
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus kategori ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminService.deleteCategory(id);
      _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori berhasil dihapus'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus kategori: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleSelectCategory(dynamic category) {
    final id = _toInt((category as Map)['id']);
    if (id <= 0) return;

    setState(() {
      if (_selectedCategoryIds.contains(id)) {
        _selectedCategoryIds.remove(id);
      } else {
        _selectedCategoryIds.add(id);
      }
    });
  }

  void _selectAllCurrent() {
    setState(() {
      for (final category in _categories) {
        final id = _toInt((category as Map)['id']);
        if (id > 0) {
          _selectedCategoryIds.add(id);
        }
      }
    });
  }

  void _setSelectAllVisible(bool value) {
    if (value) {
      _selectAllCurrent();
      return;
    }

    final visibleIds = _categories
        .map((category) => _toInt((category as Map)['id']))
        .where((id) => id > 0)
        .toSet();

    setState(() {
      _selectedCategoryIds.removeWhere((id) => visibleIds.contains(id));
    });
  }

  void _clearSelection() {
    setState(() => _selectedCategoryIds.clear());
  }

  Future<void> _bulkAction(String action) async {
    if (_selectedCategoryIds.isEmpty) return;

    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi Hapus Massal'),
          content: Text(
            'Anda akan menghapus ${_selectedCategoryIds.length} kategori sekaligus. Tindakan ini bisa berdampak ke data keluhan. Lanjutkan?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    try {
      await _adminService.bulkActionCategories(
        ids: _selectedCategoryIds.toList(),
        action: action,
      );

      await _loadCategories(forceRefresh: true);
      if (!mounted) return;

      setState(() => _selectedCategoryIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bulk action berhasil dijalankan'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bulk action gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final visibleIds = _categories
        .map((category) => _toInt((category as Map)['id']))
        .where((id) => id > 0)
        .toSet();
    final selectedVisibleCount = _selectedCategoryIds.where((id) => visibleIds.contains(id)).length;
    final allVisibleSelected = visibleIds.isNotEmpty && selectedVisibleCount == visibleIds.length;
    
    return Column(
      children: [
        // Search and Filter Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: AdminFilterPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminSectionHeader(
                  title: 'Manajemen Kategori',
                  subtitle: 'Kelola kategori aduan untuk memudahkan pengelompokan.',
                  icon: Icons.category,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Cari kategori...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (value) {
                          setState(() => _searchQuery = value);
                          _loadCategories();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list),
                      onSelected: (value) {
                        setState(() => _selectedStatus = value == 'all' ? null : value);
                        _loadCategories();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'all', child: Text('Semua Status')),
                        const PopupMenuItem(value: 'active', child: Text('Aktif')),
                        const PopupMenuItem(value: 'inactive', child: Text('Nonaktif')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      selected: allVisibleSelected,
                      onSelected: _categories.isEmpty ? null : _setSelectAllVisible,
                      label: Text('Pilih Semua Visible ($selectedVisibleCount/${visibleIds.length})'),
                    ),
                    OutlinedButton(
                      onPressed: _categories.isEmpty ? null : _selectAllCurrent,
                      child: const Text('Pilih Semua'),
                    ),
                    OutlinedButton(
                      onPressed: _selectedCategoryIds.isEmpty ? null : _clearSelection,
                      child: const Text('Hapus Pilihan'),
                    ),
                    OutlinedButton(
                      onPressed: _selectedCategoryIds.isEmpty ? null : () => _bulkAction('activate'),
                      child: Text('Aktifkan Dipilih (${_selectedCategoryIds.length})'),
                    ),
                    OutlinedButton(
                      onPressed: _selectedCategoryIds.isEmpty ? null : () => _bulkAction('deactivate'),
                      child: Text('Nonaktifkan Dipilih (${_selectedCategoryIds.length})'),
                    ),
                    OutlinedButton(
                      onPressed: _selectedCategoryIds.isEmpty ? null : () => _bulkAction('delete'),
                      child: Text('Hapus Dipilih (${_selectedCategoryIds.length})'),
                    ),
                  ],
                ),
                if (_selectedStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Chip(
                      label: Text('Filter: ${_selectedStatus == "active" ? "Aktif" : "Nonaktif"}'),
                      onDeleted: () {
                        setState(() => _selectedStatus = null);
                        _loadCategories();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (_selectedCategoryIds.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              border: Border(
                top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
                bottom: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedCategoryIds.length} kategori dipilih',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: _clearSelection,
                  child: const Text('Clear'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _bulkAction('activate'),
                  child: const Text('Aktifkan'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _bulkAction('deactivate'),
                  child: const Text('Nonaktifkan'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _bulkAction('delete'),
                  child: const Text('Hapus Dipilih'),
                ),
              ],
            ),
          ),
        
        // Categories Grid
        // Categories List
        Expanded(
          child: !_hasLoadedData
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 6,
                  itemBuilder: (context, index) => const ListItemSkeleton(),
                )
              : _categories.isEmpty
                  ? const AdminEmptyState(
                      icon: Icons.category_outlined,
                      title: 'Tidak ada kategori',
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadCategories(forceRefresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return _buildCategoryCard(category);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(dynamic category) {
    final isActive = category['is_active'] == true || category['is_active'] == 1;
    final isSelected = _selectedCategoryIds.contains(_toInt(category['id']));
    final complaintsCount = category['complaints_count'] ?? 0;

    return AdminInfoCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderColor: isSelected
          ? AppTheme.primary.withValues(alpha: 0.7)
          : (isActive ? Colors.blue.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.3)),
      padding: const EdgeInsets.all(12),
      onTap: () async {
        final changed = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminCategoryDetailScreen(
              category: Map<String, dynamic>.from(category as Map),
            ),
          ),
        );

        if (changed == true) {
          _loadCategories(forceRefresh: true);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (_) => _toggleSelectCategory(category),
            activeColor: AppTheme.primary,
          ),
          const SizedBox(width: 4),
          Expanded(
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
                          Text(
                            category['name'] ?? 'No Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category['description'] ?? 'Tidak ada deskripsi',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (value) async {
                        switch (value) {
                          case 'edit':
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditCategoryScreen(category: category),
                              ),
                            );
                            if (result == true) _loadCategories();
                            break;
                          case 'toggle_status':
                            _toggleStatus(category['id']);
                            break;
                          case 'delete':
                            _deleteCategory(category['id']);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Ubah'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle_status',
                          child: Row(
                            children: [
                              Icon(isActive ? Icons.toggle_off : Icons.toggle_on, size: 18),
                              SizedBox(width: 8),
                              Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Hapus', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: const Icon(Icons.more_vert, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AdminStatusBadge(
                      label: isActive ? 'Aktif' : 'Nonaktif',
                      color: isActive ? Colors.green : Colors.grey,
                      icon: isActive ? Icons.check_circle : Icons.cancel,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 6),
                          Text(
                            '$complaintsCount keluhan',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
