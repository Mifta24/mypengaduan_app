import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../routes/app_router.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/admin_confirm_dialog.dart';
import '../../../widgets/admin/admin_empty_state.dart';
import 'complaint_status_utils.dart';
import 'widgets/complaint_action_sheet.dart';
import 'widgets/complaint_attachment_dialog.dart';
import 'widgets/complaint_list_card.dart';
import 'widgets/complaint_status_dropdown.dart';

class AdminComplaintsTab extends StatefulWidget {
  const AdminComplaintsTab({super.key});

  @override
  State<AdminComplaintsTab> createState() => _AdminComplaintsTabState();
}

class _AdminComplaintsTabState extends State<AdminComplaintsTab>
    with AutomaticKeepAliveClientMixin {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _complaints = [];
  bool _isLoading = false;
  String? _selectedStatus;
  String _searchQuery = '';

  // Static variables for global caching
  static bool _hasLoadedDataGlobally = false;
  static List<dynamic> _cachedComplaints = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint(
        '📋 [AdminComplaintsTab] Screen initialized - will load after visible');

    // Use cached data if available
    if (_hasLoadedDataGlobally && _cachedComplaints.isNotEmpty) {
      debugPrint(
          '📋 [AdminComplaintsTab] Using cached data (${_cachedComplaints.length} items)');
      _complaints = _cachedComplaints;
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
          debugPrint(
              '📋 [AdminComplaintsTab] Screen visible - loading complaints now');
          _loadComplaints();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints({bool forceRefresh = false}) async {
    if (_isLoading) {
      debugPrint('Admin Complaints: Already loading, skipping...');
      return;
    }

    if (_hasLoadedDataGlobally && !forceRefresh) {
      debugPrint('Admin Complaints: Already loaded globally, skipping...');
      return;
    }

    if (!mounted) return;

    debugPrint('Admin Complaints: Loading... (forceRefresh: $forceRefresh)');
    setState(() => _isLoading = true);

    try {
      final response = await _adminService.getComplaints(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _selectedStatus,
        perPage: 10,
      );

      if (mounted) {
        setState(() {
          _complaints = response['data'] ?? [];
          _cachedComplaints = response['data'] ?? [];
          _hasLoadedDataGlobally = true;
          _isLoading = false;
        });
        debugPrint('Admin Complaints: Loaded ${_complaints.length} items');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Admin Complaints: Error loading - $e');
        if (forceRefresh) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      await _adminService.updateComplaintStatus(id, status);
      await _loadComplaints(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Status berhasil diupdate'),
              backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal update status: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _deleteComplaintToTrash(int id) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Pindahkan ke Trash',
      message: 'Pindahkan pengaduan ini ke trash?',
    );
    if (!confirmed) return;
    try {
      await _adminService.deleteComplaint(id);
      await _loadComplaints(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pengaduan dipindahkan ke trash'),
              backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal hapus pengaduan: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _deleteAttachment(int attachmentId) async {
    await _adminService.deleteComplaintAttachment(attachmentId);
    await _loadComplaints(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filtered = _complaints.where((c) {
      final title = c['title']?.toString().toLowerCase() ?? '';
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || title.contains(q);
    }).toList();

    return Column(
      children: [
        // ── Filter bar ──────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ComplaintStatusDropdown(
                      value: _selectedStatus,
                      hint: 'Semua Status',
                      items: const {
                        'pending': 'Menunggu',
                        'in_progress': 'Diproses',
                        'waiting_user_confirmation': 'Konfirmasi',
                        'resolved': 'Selesai',
                        'rejected': 'Ditolak',
                      },
                      onChanged: (v) {
                        setState(() => _selectedStatus = v);
                        _loadComplaints(forceRefresh: true);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await context.push(AppRouter.adminComplaintsTrash);
                      _loadComplaints(forceRefresh: true);
                    },
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: Text('Trash',
                        style: GoogleFonts.nunito(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                style: GoogleFonts.nunito(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari pengaduan...',
                  hintStyle: GoogleFonts.nunito(
                      fontSize: 14, color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _loadComplaints(forceRefresh: true);
                          })
                      : null,
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
                onChanged: (v) => setState(() => _searchQuery = v),
                onSubmitted: (_) => _loadComplaints(forceRefresh: true),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppTheme.border),

        // ── List ────────────────────────────────────────────
        Expanded(
          child: !_hasLoadedDataGlobally && _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary))
              : filtered.isEmpty
                  ? const AdminEmptyState(
                      icon: Icons.report_outlined,
                      title: 'Tidak ada pengaduan',
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadComplaints(forceRefresh: true),
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => ComplaintListCard(
                          item: filtered[i],
                          onTap: () => _openComplaint(filtered[i]),
                          onLongPress: () => _showActionSheet(filtered[i]),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Future<void> _openComplaint(dynamic item) async {
    try {
      final id = complaintIdOf(item['id']);
      await context.push('/complaint/$id');
      await _loadComplaints(forceRefresh: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showActionSheet(dynamic item) {
    showComplaintActionSheet(
      context,
      item,
      onResolve: () async {
        final result = await context.push(AppRouter.adminComplaintsResolve, extra: item);
        if (result == true) await _loadComplaints(forceRefresh: true);
      },
      onMarkInProgress: () => _updateStatus(complaintIdOf(item['id']), 'in_progress'),
      onReject: () => _updateStatus(complaintIdOf(item['id']), 'rejected'),
      onManageAttachments: () => showComplaintAttachmentDialog(
        context,
        item,
        onDeleteAttachment: _deleteAttachment,
      ),
      onMoveToTrash: () => _deleteComplaintToTrash(complaintIdOf(item['id'])),
    );
  }
}
