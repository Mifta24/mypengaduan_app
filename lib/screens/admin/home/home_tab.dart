import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/complaint_model.dart';
import '../../../services/admin_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/admin/admin_empty_state.dart';
import '../../../widgets/admin/admin_info_card.dart';
import '../../../widgets/admin/admin_section_header.dart';
import '../../../widgets/skeleton_loader.dart';
import '../../complaints/complaint_detail_screen.dart';

class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> with AutomaticKeepAliveClientMixin {
  final AdminService _adminService = AdminService();
  
  int totalComplaints = 0;
  int pendingComplaints = 0;
  int processingComplaints = 0;
  int completedComplaints = 0;
  int totalUsers = 0;
  int activeAnnouncements = 0;
  List<dynamic> recentComplaints = [];
  bool isLoading = false;
  bool _hasLoadedData = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 [AdminHomeTab] Screen initialized - will load after visible');
  }

  bool _hasLoadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load only once when screen becomes visible
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          debugPrint('🏠 [AdminHomeTab] Screen visible - loading data now');
          // Check if user is still authenticated before loading
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isAuthenticated && !_hasLoadedData) {
            _loadStatistics();
          }
        }
      });
    }
  }

  Future<void> _loadStatistics({bool forceRefresh = false}) async {
    if (!mounted) return;
    
    // Check authentication state before proceeding
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      debugPrint('⚠️ User not authenticated, skipping statistics load');
      return;
    }
    
    // Only show loading on force refresh (pull to refresh)
    if (forceRefresh) {
      setState(() => isLoading = true);
    }
    
    try {
      // Load dashboard data (includes stats and recent complaints)
      final dashboard = await _adminService.getDashboard();
      
      if (mounted) {
        setState(() {
          final data = dashboard['data'] ?? dashboard;
          
          // Parse statistics - API returns objects with 'count' field
          final totalComplaintsObj = data['total_complaints'];
          final totalUsersObj = data['total_users'];
          final complaintsData = data['complaints'] ?? {};
          final announcementsData = data['announcements'] ?? {};
          
          totalComplaints = totalComplaintsObj is Map ? (totalComplaintsObj['count'] ?? 0) : 0;
          totalUsers = totalUsersObj is Map ? (totalUsersObj['count'] ?? 0) : 0;
          
          // Parse complaint statuses from complaints object
          pendingComplaints = complaintsData['pending'] ?? 0;
          processingComplaints = complaintsData['in_progress'] ?? 0;
          completedComplaints = complaintsData['resolved'] ?? 0;
          
          // Parse active announcements from announcements object
          activeAnnouncements = announcementsData['active'] ?? 0;
          
          // Parse recent complaints (if exists)
          recentComplaints = data['recent_complaints'] ?? [];
          
          isLoading = false;
          _hasLoadedData = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      
      // Check if it's token expiration error
      if (e.toString().contains('Token expired') && mounted) {
        // Auto-logout and redirect to landing page
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
        
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/landing', (route) => false);
        }
        return;
      }
      
      if (mounted) {
        setState(() => isLoading = false);
        if (forceRefresh) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat statistik: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () => _loadStatistics(forceRefresh: true),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(
              title: 'Dashboard Admin',
              subtitle: 'Pantau ringkasan kinerja sistem dan aktivitas terbaru.',
              icon: Icons.dashboard,
            ),
            const SizedBox(height: 16),
            
            // Show skeleton loading only on first load
            if (!_hasLoadedData)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: List.generate(6, (_) => const StatCardSkeleton()),
              )
            else
              // Statistics Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    context,
                    'Total Pengaduan',
                    totalComplaints.toString(),
                    Icons.report_problem,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    context,
                    'Pending',
                    pendingComplaints.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    context,
                    'Diproses',
                    processingComplaints.toString(),
                    Icons.sync,
                    Colors.purple,
                  ),
                  _buildStatCard(
                    context,
                    'Selesai',
                    completedComplaints.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatCard(
                    context,
                    'Total Pengguna',
                    totalUsers.toString(),
                    Icons.people,
                    Colors.teal,
                  ),
                  _buildStatCard(
                    context,
                    'Pengumuman Aktif',
                    activeAnnouncements.toString(),
                    Icons.announcement,
                    Colors.red,
                  ),
                ],
              ),
            const SizedBox(height: 24),
            
            // Recent Complaints Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.border),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pengaduan Terbaru',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    
                    // Show loading state
                    if (!_hasLoadedData)
                      ...List.generate(3, (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: ListItemSkeleton(),
                      ))
                    // Show empty state
                    else if (recentComplaints.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.inbox,
                        title: 'Belum ada pengaduan',
                      )
                    // Show recent complaints
                    else
                      ...recentComplaints.take(5).map((complaint) {
                        final status = complaint['status'] ?? 'pending';
                        final createdAt = DateTime.tryParse(complaint['created_at'] ?? '');
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () async {
                              try {
                                final complaintModel = Complaint.fromJson(
                                  Map<String, dynamic>.from(complaint as Map),
                                );
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ComplaintDetailScreen(complaint: complaintModel),
                                  ),
                                );
                              } catch (_) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Detail pengaduan tidak tersedia'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getStatusIcon(status),
                                      color: _getStatusColor(status),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          complaint['title'] ?? 'No Title',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(status),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _getStatusLabel(status),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                createdAt != null 
                                                  ? _formatRelativeTime(createdAt)
                                                  : '-',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return AdminInfoCard(
      borderColor: AppTheme.border,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
      case 'inprogress':
      case 'processing':
        return Colors.blue;
      case 'resolved':
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'in_progress':
      case 'inprogress':
      case 'processing':
        return Icons.refresh;
      case 'resolved':
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
      case 'inprogress':
      case 'processing':
        return 'Diproses';
      case 'resolved':
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}

