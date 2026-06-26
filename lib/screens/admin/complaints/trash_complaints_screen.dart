import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/admin_confirm_dialog.dart';
import '../../../widgets/admin/admin_empty_state.dart';

class AdminTrashComplaintsScreen extends StatefulWidget {
  const AdminTrashComplaintsScreen({super.key});

  @override
  State<AdminTrashComplaintsScreen> createState() => _AdminTrashComplaintsScreenState();
}

class _AdminTrashComplaintsScreenState extends State<AdminTrashComplaintsScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMorePages = false;
  int _currentPage = 1;
  int _activePage = 1;
  int _lastPage = 1;
  int _totalItems = 0;
  List<dynamic> _items = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTrashedComplaints(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || _isLoadingMore || !_hasMorePages) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 120) {
      _loadTrashedComplaints(reset: false);
    }
  }

  Future<void> _loadTrashedComplaints({required bool reset}) async {
    if (!mounted) return;

    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _activePage = 1;
        _lastPage = 1;
        _totalItems = 0;
        _hasMorePages = false;
      });
    } else {
      if (_isLoadingMore || !_hasMorePages) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final response = await _adminService.getTrashedComplaints(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        perPage: 20,
        page: _currentPage,
      );

      final rows = (response['data'] as List?) ?? const [];
      final currentPage = _toInt(response['current_page'] ?? response['meta']?['current_page']);
      final lastPage = _toInt(response['last_page'] ?? response['meta']?['last_page']);
      final total = _toInt(response['total'] ?? response['meta']?['total']);

      if (!mounted) return;
      setState(() {
        if (reset) {
          _items = rows;
        } else {
          _items.addAll(rows);
        }

        _currentPage = currentPage > 0 ? currentPage + 1 : _currentPage + 1;
        _activePage = currentPage > 0 ? currentPage : _activePage;
        _lastPage = lastPage > 0 ? lastPage : _lastPage;
        _totalItems = total > 0 ? total : _totalItems;
        _hasMorePages = lastPage > 0 ? currentPage < lastPage : rows.isNotEmpty;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat trash complaints: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  Future<void> _restore(int id) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Restore Pengaduan',
      message: 'Kembalikan pengaduan ini dari trash?',
      confirmText: 'Restore',
      confirmColor: AppTheme.primary,
    );
    if (!confirmed) return;
    try {
      await _adminService.restoreComplaint(id);
      await _loadTrashedComplaints(reset: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaduan berhasil direstore'), backgroundColor: AppTheme.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal restore: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  Future<void> _forceDelete(int id) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Hapus Permanen',
      message: 'Data akan dihapus permanen dan tidak bisa dikembalikan. Lanjutkan?',
      confirmText: 'Hapus Permanen',
    );
    if (!confirmed) return;

    try {
      await _adminService.forceDeleteComplaint(id);
      await _loadTrashedComplaints(reset: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaduan dihapus permanen'), backgroundColor: AppTheme.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal hapus permanen: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Trash Complaints',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.nunito(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Cari complaint di trash...',
                          hintStyle: GoogleFonts.nunito(
                              fontSize: 14, color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppTheme.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppTheme.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppTheme.primary, width: 1.5)),
                        ),
                        onSubmitted: (value) {
                          setState(() => _searchQuery = value.trim());
                          _loadTrashedComplaints(reset: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _loadTrashedComplaints(reset: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Refresh', style: GoogleFonts.nunito()),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Halaman $_activePage/$_lastPage • Total $_totalItems data',
                    style: GoogleFonts.nunito(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.border),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : _items.isEmpty
                    ? const AdminEmptyState(
                        icon: Icons.delete_outline,
                        title: 'Trash complaints kosong',
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length + (_hasMorePages || _isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _items.length) {
                            if (_isLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: OutlinedButton(
                                  onPressed: () => _loadTrashedComplaints(reset: false),
                                  child: const Text('Muat Lebih Banyak'),
                                ),
                              ),
                            );
                          }

                          final item = _items[index] as Map;
                          final id = _toInt(item['id']);
                          final title = item['title']?.toString() ?? item['description']?.toString() ?? 'Tanpa Judul';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: ListTile(
                              title: Text(title,
                                  style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppTheme.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Text('ID: $id',
                                  style: GoogleFonts.nunito(
                                      fontSize: 11, color: AppTheme.textSecondary)),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: id > 0 ? () => _restore(id) : null,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                      side: const BorderSide(color: AppTheme.primary),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text('Restore', style: GoogleFonts.nunito(fontSize: 12)),
                                  ),
                                  OutlinedButton(
                                    onPressed: id > 0 ? () => _forceDelete(id) : null,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.danger,
                                      side: const BorderSide(color: AppTheme.danger),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text('Hapus Permanen', style: GoogleFonts.nunito(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
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
}
