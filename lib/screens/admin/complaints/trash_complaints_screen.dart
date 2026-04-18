import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';

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
        SnackBar(content: Text('Gagal memuat trash complaints: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _restore(int id) async {
    try {
      await _adminService.restoreComplaint(id);
      await _loadTrashedComplaints(reset: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaduan berhasil direstore'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal restore: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _forceDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Permanen'),
        content: const Text('Data akan dihapus permanen dan tidak bisa dikembalikan. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Permanen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminService.forceDeleteComplaint(id);
      await _loadTrashedComplaints(reset: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaduan dihapus permanen'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal hapus permanen: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash Complaints'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Cari complaint di trash...',
                          prefixIcon: Icon(Icons.search),
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
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Halaman $_activePage/$_lastPage • Total $_totalItems data',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('Trash complaints kosong'))
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

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text('ID: $id'),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: id > 0 ? () => _restore(id) : null,
                                    child: const Text('Restore'),
                                  ),
                                  OutlinedButton(
                                    onPressed: id > 0 ? () => _forceDelete(id) : null,
                                    child: const Text('Hapus Permanen'),
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
