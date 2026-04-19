import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/admin_filter_panel.dart';
import '../../../widgets/admin/admin_empty_state.dart';
import '../../../widgets/admin/admin_info_card.dart';
import '../../../widgets/admin/admin_section_header.dart';
import '../../../widgets/admin/admin_status_badge.dart';
import '../../../widgets/skeleton_loader.dart';
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        // Search and Filter Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: AdminFilterPanel(
            child: Column(
              children: [
                const AdminSectionHeader(
                  title: 'Manajemen Pengaduan',
                  subtitle:
                      'Kelola aduan warga, pantau progres, dan tindak lanjut.',
                  icon: Icons.report_problem,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Cari pengaduan...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (value) {
                          setState(() => _searchQuery = value);
                          _loadComplaints();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list),
                      onSelected: (value) {
                        setState(() =>
                            _selectedStatus = value == 'all' ? null : value);
                        _loadComplaints();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'all', child: Text('Semua Status')),
                        const PopupMenuItem(
                            value: 'pending', child: Text('Pending')),
                        const PopupMenuItem(
                            value: 'in_progress', child: Text('Dalam Proses')),
                        const PopupMenuItem(
                            value: 'waiting_user_confirmation',
                            child: Text('Menunggu Konfirmasi User')),
                        const PopupMenuItem(
                            value: 'resolved', child: Text('Selesai')),
                        const PopupMenuItem(
                            value: 'rejected', child: Text('Ditolak')),
                      ],
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const AdminTrashComplaintsScreen()),
                        );
                        await _loadComplaints(forceRefresh: true);
                      },
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Lihat Trash'),
                    ),
                  ],
                ),
                if (_selectedStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Chip(
                      label: Text('Filter: ${_statusLabel(_selectedStatus!)}'),
                      onDeleted: () {
                        setState(() => _selectedStatus = null);
                        _loadComplaints();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Complaints List
        Expanded(
          child: !_hasLoadedDataGlobally
              ? ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: 5, // Show 5 skeleton items
                  itemBuilder: (context, index) => const ListItemSkeleton(),
                )
              : _complaints.isEmpty
                  ? const AdminEmptyState(
                      icon: Icons.report_problem_outlined,
                      title: 'Tidak ada pengaduan',
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadComplaints(forceRefresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _complaints.length,
                        itemBuilder: (context, index) {
                          final complaint = _complaints[index];
                          return _buildComplaintCard(complaint);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildComplaintCard(dynamic complaint) {
    final status = complaint['status']?.toString().toLowerCase() ?? 'pending';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        break;
      case 'processing':
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.autorenew;
        break;
      case 'waiting_user_confirmation':
        statusColor = Colors.deepOrange;
        statusIcon = Icons.hourglass_top;
        break;
      case 'resolved':
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return AdminInfoCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderColor: statusColor.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(16),
      onTap: () async {
        try {
          final complaintModel = Complaint.fromJson(complaint);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComplaintDetailScreen(
                complaint: complaintModel,
              ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
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
                                complaint['title'] ?? 'No Title',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${complaint['id']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          onSelected: (value) async {
                            if (value == 'delete') {
                              _deleteComplaintToTrash(_toInt(complaint['id']));
                              return;
                            }

                            if (value == 'delete_attachment') {
                              _showAttachmentDeleteDialog(complaint);
                              return;
                            }

                            if (value == 'resolved') {
                              // Show resolve screen with form
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ResolveComplaintScreen(complaint: complaint),
                                ),
                              );
                              if (result == true) {
                                await _loadComplaints(forceRefresh: true);
                              }
                            } else {
                              _updateStatus(complaint['id'], value);
                            }
                          },
                          itemBuilder: (context) {
                            return [
                              const PopupMenuItem(
                                value: 'in_progress',
                                child: Row(
                                  children: [
                                    Icon(Icons.autorenew, size: 18, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Tandai Dalam Proses'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'resolved',
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 18, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Tandai Selesai'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'rejected',
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Tolak'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete_attachment',
                                child: Row(
                                  children: [
                                    Icon(Icons.attachment, size: 18),
                                    SizedBox(width: 8),
                                    Text('Hapus Attachment'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Pindah ke Trash'),
                                  ],
                                ),
                              ),
                            ];
                          },
                          child: const Icon(Icons.more_vert, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      complaint['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    AdminStatusBadge(
                      label: _statusLabel(status),
                      color: statusColor,
                      icon: statusIcon,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
      case 'in_progress':
        return 'Dalam Proses';
      case 'waiting_user_confirmation':
        return 'Menunggu Konfirmasi User';
      case 'resolved':
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
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
}
