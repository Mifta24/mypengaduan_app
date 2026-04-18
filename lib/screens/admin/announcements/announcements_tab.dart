import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/admin_filter_panel.dart';
import '../../../widgets/admin/admin_empty_state.dart';
import '../../../widgets/admin/admin_info_card.dart';
import '../../../widgets/admin/admin_section_header.dart';
import '../../../widgets/admin/admin_status_badge.dart';
import '../../../widgets/skeleton_loader.dart';
import 'announcement_detail_screen.dart';
import 'edit_announcement_screen.dart';

class AdminAnnouncementsTab extends StatefulWidget {
  const AdminAnnouncementsTab({super.key});

  @override
  State<AdminAnnouncementsTab> createState() => _AdminAnnouncementsTabState();

  void reload() {
    // Access state to reload
  }
}

class _AdminAnnouncementsTabState extends State<AdminAnnouncementsTab> with AutomaticKeepAliveClientMixin {
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
    debugPrint('📢 [AdminAnnouncementsTab] Screen initialized - will load after visible');
    
    // Use cached data if available
    if (_hasLoadedDataGlobally && _cachedAnnouncements.isNotEmpty) {
      debugPrint('📢 [AdminAnnouncementsTab] Using cached data (${_cachedAnnouncements.length} items)');
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
          debugPrint('📢 [AdminAnnouncementsTab] Screen visible - loading announcements now');
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
    // Skip if already loading
    if (_isLoading) {
      debugPrint('Admin Announcements: Already loading, skipping...');
      return;
    }
    
    // Skip if already loaded globally and not forcing refresh
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
          _cachedAnnouncements = response['data'] ?? []; // Update cache
          _hasLoadedDataGlobally = true; // Mark as loaded globally
          _isLoading = false;
        });
        debugPrint('Admin Announcements: Loaded ${_announcements.length} items');
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

  Future<void> _toggleStatus(int id) async {
    try {
      await _adminService.toggleAnnouncementStatus(id);
      _loadAnnouncements();
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

  Future<void> _publishAnnouncement(int id) async {
    try {
      await _adminService.publishAnnouncement(id);
      _loadAnnouncements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengumuman berhasil dipublikasi'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal publikasi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Column(
      children: [
        // Action Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: AdminFilterPanel(
            child: Column(
              children: [
                const AdminSectionHeader(
                  title: 'Manajemen Pengumuman',
                  subtitle: 'Kelola konten pengumuman, prioritas, dan status tayang.',
                  icon: Icons.announcement,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Cari pengumuman...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (value) {
                          setState(() => _searchQuery = value);
                          _loadAnnouncements();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list),
                      onSelected: (value) {
                        setState(() => _selectedStatus = value == 'all' ? null : value);
                        _loadAnnouncements();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'all', child: Text('Semua')),
                        const PopupMenuItem(value: 'published', child: Text('Dipublikasi')),
                        const PopupMenuItem(value: 'draft', child: Text('Draft')),
                      ],
                    ),
                  ],
                ),
                if (_selectedStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Chip(
                      label: Text('Filter: $_selectedStatus'),
                      onDeleted: () {
                        setState(() => _selectedStatus = null);
                        _loadAnnouncements();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Announcements List
        Expanded(
          child: !_hasLoadedDataGlobally && _isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: 5,
                  itemBuilder: (context, index) => const ListItemSkeleton(),
                )
              : _announcements.isEmpty
                  ? const AdminEmptyState(
                      icon: Icons.announcement_outlined,
                      title: 'Tidak ada pengumuman',
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadAnnouncements(forceRefresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _announcements.length,
                        itemBuilder: (context, index) {
                          final announcement = _announcements[index];
                          return _buildAnnouncementCard(announcement);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(dynamic announcement) {
    final isActive = announcement['is_active'] == true || announcement['is_active'] == 1;
    final isSticky = announcement['is_sticky'] == true || announcement['is_sticky'] == 1;
    final priority = announcement['priority']?.toString().toLowerCase() ?? 'medium';
    
    Color priorityColor;
    IconData priorityIcon;
    switch (priority) {
      case 'urgent':
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case 'high':
        priorityColor = Colors.orange;
        priorityIcon = Icons.arrow_upward;
        break;
      case 'medium':
        priorityColor = Colors.blue;
        priorityIcon = Icons.remove;
        break;
      case 'low':
        priorityColor = Colors.green;
        priorityIcon = Icons.arrow_downward;
        break;
      default:
        priorityColor = Colors.grey;
        priorityIcon = Icons.help_outline;
    }

    return AdminInfoCard(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSticky ? 2 : 0,
      borderColor: isSticky ? Colors.red.withValues(alpha: 0.5) : priorityColor.withValues(alpha: 0.3),
      borderWidth: isSticky ? 2 : 1,
      padding: const EdgeInsets.all(16),
      onTap: () {
        _showAnnouncementDetailDialog(announcement);
      },
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isSticky)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.push_pin, color: Colors.red, size: 20),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.announcement, color: priorityColor, size: 20),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSticky)
                        const Text(
                          'Disematkan',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'view':
                        _showAnnouncementDetailDialog(announcement);
                        break;
                      case 'edit':
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditAnnouncementScreen(announcement: announcement),
                          ),
                        );
                        if (result == true) _loadAnnouncements();
                        break;
                      case 'toggle_status':
                        _toggleStatus(announcement['id']);
                        break;
                      case 'publish':
                        _publishAnnouncement(announcement['id']);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text('Detail'),
                        ],
                      ),
                    ),
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
                          Icon(isActive ? Icons.visibility_off : Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
                        ],
                      ),
                    ),
                    if (!isActive)
                      const PopupMenuItem(
                        value: 'publish',
                        child: Row(
                          children: [
                            Icon(Icons.publish, size: 18),
                            SizedBox(width: 8),
                            Text('Terbitkan'),
                          ],
                        ),
                      ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              announcement['summary'] ?? announcement['content'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AdminStatusBadge(
                  label: _priorityLabel(priority),
                  color: priorityColor,
                  icon: priorityIcon,
                ),
                const SizedBox(width: 8),
                AdminStatusBadge(
                  label: isActive ? 'Aktif' : 'Nonaktif',
                  color: isActive ? Colors.green : Colors.grey,
                  icon: isActive ? Icons.visibility : Icons.visibility_off,
                ),
              ],
            ),
          ],
        ),
    );
  }

  void _showAnnouncementDetailDialog(dynamic announcement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminAnnouncementDetailScreen(
          announcement: Map<String, dynamic>.from(announcement as Map),
        ),
      ),
    ).then((changed) {
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
}
