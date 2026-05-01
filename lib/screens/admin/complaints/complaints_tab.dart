import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import '../../../models/complaint_model.dart';
import '../../complaints/complaint_detail_screen.dart';
import 'resolve_complaint_screen.dart';
import 'trash_complaints_screen.dart';

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
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal update status: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteComplaintToTrash(int id) async {
    try {
      await _adminService.deleteComplaint(id);
      await _loadComplaints(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pengaduan dipindahkan ke trash'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal hapus pengaduan: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showAttachmentDeleteDialog(dynamic complaint) async {
    final attachments = _extractAttachments(complaint);
    if (attachments.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tidak ada attachment pada pengaduan ini')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Hapus Attachment'),
          content: SizedBox(
            width: 420,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: attachments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = attachments[index];
                final id = _toInt(item['id']);
                final name = item['name']?.toString() ??
                    item['filename']?.toString() ??
                    item['file_name']?.toString() ??
                    'Attachment #$id';

                return Row(
                  children: [
                    Expanded(
                        child: Text(name,
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                    TextButton(
                      onPressed: id <= 0
                          ? null
                          : () async {
                              try {
                                await _adminService
                                    .deleteComplaintAttachment(id);
                                setLocalState(() {
                                  attachments.removeAt(index);
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Attachment berhasil dihapus'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                                await _loadComplaints(forceRefresh: true);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context)
                                      .showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Gagal hapus attachment: $e'),
                                        backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                      child: const Text('Hapus',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup')),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
      case 'in_progress':
        return 'Diproses';
      case 'waiting_user_confirmation':
        return 'Konfirmasi';
      case 'resolved':
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'in_progress':
      case 'processing':
        return const Color(0xFF0891B2);
      case 'waiting_user_confirmation':
        return const Color(0xFFEA580C);
      case 'resolved':
      case 'completed':
        return AppTheme.primary;
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  List<Map<String, dynamic>> _extractAttachments(dynamic complaint) {
    if (complaint is! Map) return const [];

    final raw = complaint['attachments'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return const [];
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
                    child: _dropdownFilter(
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
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const AdminTrashComplaintsScreen()));
                      _loadComplaints(forceRefresh: true);
                    },
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: Text('Trash',
                        style: GoogleFonts.nunito(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
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
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.report_outlined,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Tidak ada pengaduan',
                              style: GoogleFonts.nunito(
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadComplaints(forceRefresh: true),
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) =>
                            _buildComplaintCard(filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _dropdownFilter({
    required String? value,
    required String hint,
    required Map<String, String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: Colors.grey.shade500)),
          style: GoogleFonts.nunito(
              fontSize: 13, color: AppTheme.textPrimary),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          items: [
            DropdownMenuItem(
                value: null,
                child: Text(hint, style: GoogleFonts.nunito(fontSize: 13))),
            ...items.entries.map((e) => DropdownMenuItem(
                value: e.key,
                child:
                    Text(e.value, style: GoogleFonts.nunito(fontSize: 13)))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildComplaintCard(dynamic item) {
    final status =
        item['status']?.toString().toLowerCase() ?? 'pending';
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);

    final userName = item['user'] is Map
        ? (item['user']['name']?.toString() ?? 'P')
        : 'P';
    final firstLetter =
        userName.isNotEmpty ? userName[0].toUpperCase() : 'P';

    final title = item['title']?.toString() ?? 'Tanpa Judul';
    final category = item['category'] is Map
        ? item['category']['name']?.toString()
        : item['category_name']?.toString();
    final location = item['address']?.toString() ??
        item['location']?.toString() ??
        '';
    final createdAt = item['created_at']?.toString() ?? '';
    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        dateStr =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        dateStr = createdAt.length > 10 ? createdAt.substring(0, 10) : createdAt;
      }
    }

    return GestureDetector(
      onTap: () async {
        try {
          final complaintModel = Complaint.fromJson(item);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComplaintDetailScreen(complaint: complaintModel),
            ),
          );
          await _loadComplaints(forceRefresh: true);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.toString()}')),
            );
          }
        }
      },
      onLongPress: () => _showActionSheet(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.15),
                ),
                alignment: Alignment.center,
                child: Text(
                  firstLetter,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category != null && category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (location.isNotEmpty) location,
                        if (dateStr.isNotEmpty) dateStr,
                      ].join(' • '),
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status badge + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right,
                      size: 16, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionSheet(dynamic item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item['title']?.toString() ?? 'Aksi Pengaduan',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ResolveComplaintScreen(complaint: item),
                    ),
                  );
                  if (result == true) {
                    await _loadComplaints(forceRefresh: true);
                  }
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text('Selesaikan',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _updateStatus(_toInt(item['id']), 'in_progress');
                },
                icon: const Icon(Icons.autorenew, size: 18),
                label: Text('Tandai Diproses',
                    style: GoogleFonts.nunito()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _updateStatus(_toInt(item['id']), 'rejected');
                },
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: Text('Tolak', style: GoogleFonts.nunito()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAttachmentDeleteDialog(item);
                },
                icon: const Icon(Icons.attach_file, size: 18),
                label: Text('Hapus Attachment',
                    style: GoogleFonts.nunito()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteComplaintToTrash(_toInt(item['id']));
                },
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: Text('Pindah Trash',
                    style: GoogleFonts.nunito(color: Colors.red)),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}