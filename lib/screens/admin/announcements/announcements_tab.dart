import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../routes/app_router.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/admin_confirm_dialog.dart';
import '../../../widgets/admin/admin_empty_state.dart';

class AdminAnnouncementsTab extends StatefulWidget {
  const AdminAnnouncementsTab({super.key});

  @override
  State<AdminAnnouncementsTab> createState() => _AdminAnnouncementsTabState();

  void reload() {
    // Access state to reload
  }
}

class _AdminAnnouncementsTabState extends State<AdminAnnouncementsTab>
    with AutomaticKeepAliveClientMixin {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _announcements = [];
  bool _isLoading = false;
  String? _selectedStatus;
  String _searchQuery = '';

  // Static variables for global caching
  static bool _hasLoadedDataGlobally = false;
  static List<dynamic> _cachedAnnouncements = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint(
        '📢 [AdminAnnouncementsTab] Screen initialized - will load after visible');

    // Use cached data if available
    if (_hasLoadedDataGlobally && _cachedAnnouncements.isNotEmpty) {
      debugPrint(
          '📢 [AdminAnnouncementsTab] Using cached data (${_cachedAnnouncements.length} items)');
      _announcements = _cachedAnnouncements;
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
              '📢 [AdminAnnouncementsTab] Screen visible - loading announcements now');
          _loadAnnouncements();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements({bool forceRefresh = false}) async {
    if (_isLoading) {
      debugPrint('Admin Announcements: Already loading, skipping...');
      return;
    }

    if (_hasLoadedDataGlobally && !forceRefresh) {
      debugPrint('Admin Announcements: Already loaded globally, skipping...');
      return;
    }

    if (!mounted) return;

    debugPrint('Admin Announcements: Loading... (forceRefresh: $forceRefresh)');
    setState(() => _isLoading = true);

    try {
      final response = await _adminService.getAnnouncements(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _selectedStatus,
        perPage: 10,
      );

      if (mounted) {
        setState(() {
          _announcements = response['data'] ?? [];
          _cachedAnnouncements = response['data'] ?? [];
          _hasLoadedDataGlobally = true;
          _isLoading = false;
        });
        debugPrint(
            'Admin Announcements: Loaded ${_announcements.length} items');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Admin Announcements: Error loading - $e');
        if (forceRefresh) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _deleteAnnouncement(int id) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Konfirmasi Hapus',
      message:
          'Apakah Anda yakin ingin menghapus pengumuman ini? Tindakan ini tidak dapat dibatalkan.',
    );
    if (!confirmed) return;
    try {
      await _adminService.deleteAnnouncement(id);
      await _loadAnnouncements(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pengumuman berhasil dihapus'),
              backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal hapus: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _showAnnouncementDetailDialog(dynamic announcement) {
    context
        .push(
      AppRouter.adminAnnouncementDetail,
      extra: Map<String, dynamic>.from(announcement as Map),
    )
        .then((changed) {
      if (changed == true) {
        _loadAnnouncements(forceRefresh: true);
      }
    });
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'urgent':
        return 'Urgent';
      case 'high':
        return 'Tinggi';
      case 'medium':
        return 'Sedang';
      case 'low':
        return 'Rendah';
      default:
        return 'Normal';
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
      case 'high':
        return AppTheme.danger;
      case 'medium':
        return AppTheme.warning;
      case 'low':
        return AppTheme.success;
      default:
        return AppTheme.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final filtered = _announcements.where((a) {
      final title = a['title']?.toString().toLowerCase() ?? '';
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty || title.contains(q);

      if (_selectedStatus == null) return matchSearch;
      // Use computed `status` field from API ('published' | 'unpublished')
      final status = a['status']?.toString() ?? '';
      if (_selectedStatus == 'published')
        return matchSearch && status == 'published';
      if (_selectedStatus == 'draft')
        return matchSearch && status != 'published';
      return matchSearch;
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
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.nunito(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cari pengumuman...',
                        hintStyle: GoogleFonts.nunito(
                            fontSize: 14, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
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
                    ),
                  ),
                  const SizedBox(width: 10),
                  _statusDropdown(),
                ],
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
                      icon: Icons.announcement_outlined,
                      title: 'Tidak ada pengumuman',
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadAnnouncements(forceRefresh: true),
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) =>
                            _buildAnnouncementCard(filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _statusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          hint: Text('Semua',
              style: GoogleFonts.nunito(
                  fontSize: 13, color: Colors.grey.shade500)),
          style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textPrimary),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: [
            DropdownMenuItem(
                value: null,
                child: Text('Semua', style: GoogleFonts.nunito(fontSize: 13))),
            DropdownMenuItem(
                value: 'published',
                child:
                    Text('Published', style: GoogleFonts.nunito(fontSize: 13))),
            DropdownMenuItem(
                value: 'draft',
                child: Text('Draft', style: GoogleFonts.nunito(fontSize: 13))),
          ],
          onChanged: (v) => setState(() => _selectedStatus = v),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(dynamic a) {
    final status = a['status']?.toString() ?? '';
    final isPublished = status == 'published';
    final priority = a['priority']?.toString().toLowerCase() ?? 'medium';
    final priorityColor = _priorityColor(priority);
    final priorityLabel = _priorityLabel(priority);

    final viewsCount = (a['views_count'] as num?)?.toInt() ?? 0;
    final title = a['title']?.toString() ?? 'Tanpa Judul';
    final publishedAt =
        a['published_at']?.toString() ?? a['created_at']?.toString() ?? '';
    String dateStr = '';
    if (publishedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(publishedAt).toLocal();
        dateStr =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        dateStr = publishedAt.length > 10
            ? publishedAt.substring(0, 10)
            : publishedAt;
      }
    }

    return GestureDetector(
      onTap: () => _showAnnouncementDetailDialog(a),
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left priority strip
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Priority pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                priorityLabel,
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: priorityColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              title,
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (dateStr.isNotEmpty)
                              Text(
                                dateStr,
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                // Status chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isPublished
                                        ? AppTheme.primary
                                            .withValues(alpha: 0.1)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isPublished ? 'Published' : 'Draft',
                                    style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isPublished
                                          ? AppTheme.primary
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Views count
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.visibility_outlined,
                                        size: 11, color: Colors.grey.shade400),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$viewsCount',
                                      style: GoogleFonts.nunito(
                                          fontSize: 10,
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Edit / Hapus actions
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final result = await context.push(
                                AppRouter.adminAnnouncementsEdit,
                                extra: a,
                              );
                              if (result == true) {
                                _loadAnnouncements(forceRefresh: true);
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text('Edit',
                                style: GoogleFonts.nunito(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          Container(
                              width: 1,
                              height: 14,
                              color: Colors.grey.shade300),
                          TextButton(
                            onPressed: () =>
                                _deleteAnnouncement(_toInt(a['id'])),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.danger,
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text('Hapus',
                                style: GoogleFonts.nunito(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
