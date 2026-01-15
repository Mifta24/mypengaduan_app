import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../home/landing_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminHomeTab(),
    const AdminComplaintsTab(),
    const AdminUsersTab(),
    const AdminAnnouncementsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'profile') {
                // TODO: Navigate to profile
              } else if (value == 'logout') {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LandingScreen()),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user?.name ?? 'Admin',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem),
            label: 'Pengaduan',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Pengguna',
          ),
          NavigationDestination(
            icon: Icon(Icons.announcement),
            label: 'Pengumuman',
          ),
        ],
      ),
    );
  }
}

// Tab: Dashboard/Home
class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  final AdminService _adminService = AdminService();
  
  int totalComplaints = 0;
  int pendingComplaints = 0;
  int processingComplaints = 0;
  int completedComplaints = 0;
  int totalUsers = 0;
  int activeAnnouncements = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Wait for widget to be fully mounted before loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatistics();
    });
  }

  Future<void> _loadStatistics() async {
    if (!mounted) return;
    
    setState(() => isLoading = true);
    
    try {
      final stats = await _adminService.getQuickStats();
      
      print('===== ADMIN STATISTICS DEBUG =====');
      print('Quick stats: $stats');
      print('==================================');
      
      if (mounted) {
        setState(() {
          final data = stats['data'] ?? stats;
          totalComplaints = data['total_complaints'] ?? 0;
          pendingComplaints = data['pending_complaints'] ?? 0;
          processingComplaints = data['processing_complaints'] ?? 0;
          completedComplaints = data['completed_complaints'] ?? 0;
          totalUsers = data['total_users'] ?? 0;
          activeAnnouncements = data['active_announcements'] ?? 0;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat statistik: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pengaduan Terbaru',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Switch to complaints tab
                    final dashboardState = context.findAncestorStateOfType<_AdminDashboardScreenState>();
                    dashboardState?.setState(() {
                      dashboardState._selectedIndex = 1;
                    });
                  },
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Placeholder for complaints list
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tarik ke bawah untuk refresh',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


// Tab: Complaints Management
class AdminComplaintsTab extends StatefulWidget {
  const AdminComplaintsTab({super.key});

  @override
  State<AdminComplaintsTab> createState() => _AdminComplaintsTabState();
}

class _AdminComplaintsTabState extends State<AdminComplaintsTab> with AutomaticKeepAliveClientMixin {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _complaints = [];
  bool _isLoading = false;
  String? _selectedStatus;
  String _searchQuery = '';
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _adminService.getComplaints(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _selectedStatus,
      );
      
      setState(() {
        _complaints = response['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      await _adminService.updateComplaintStatus(id, status);
      _loadComplaints();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status berhasil diupdate'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Column(
      children: [
        // Search and Filter Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari pengaduan...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      setState(() => _selectedStatus = value == 'all' ? null : value);
                      _loadComplaints();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'all', child: Text('Semua Status')),
                      const PopupMenuItem(value: 'pending', child: Text('Pending')),
                      const PopupMenuItem(value: 'processing', child: Text('Diproses')),
                      const PopupMenuItem(value: 'in_progress', child: Text('Dalam Progress')),
                      const PopupMenuItem(value: 'resolved', child: Text('Selesai')),
                      const PopupMenuItem(value: 'rejected', child: Text('Ditolak')),
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
                      _loadComplaints();
                    },
                  ),
                ),
            ],
          ),
        ),
        
        // Complaints List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _complaints.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.report_problem_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Tidak ada pengaduan', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadComplaints,
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
    
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'processing':
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'resolved':
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          complaint['title'] ?? 'No Title',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(complaint['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ID: ${complaint['id']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') {
              // TODO: Show detail
            } else {
              _updateStatus(complaint['id'], value);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('Lihat Detail')),
            const PopupMenuItem(value: 'processing', child: Text('Set Diproses')),
            const PopupMenuItem(value: 'resolved', child: Text('Set Selesai')),
            const PopupMenuItem(value: 'rejected', child: Text('Tolak')),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

// Tab: Users Management
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> with AutomaticKeepAliveClientMixin {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _users = [];
  bool _isLoading = false;
  String? _selectedRole;
  String _searchQuery = '';
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _adminService.getUsers(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        role: _selectedRole,
      );
      
      setState(() {
        _users = response['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _verifyUser(int id) async {
    try {
      await _adminService.verifyUser(id);
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User berhasil diverifikasi'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal verifikasi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _changeRole(int id, String role) async {
    try {
      await _adminService.changeUserRole(id, role);
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role berhasil diubah'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ubah role: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Column(
      children: [
        // Search and Filter Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari pengguna...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (value) {
                        setState(() => _searchQuery = value);
                        _loadUsers();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list),
                    onSelected: (value) {
                      setState(() => _selectedRole = value == 'all' ? null : value);
                      _loadUsers();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'all', child: Text('Semua Role')),
                      const PopupMenuItem(value: 'admin', child: Text('Admin')),
                      const PopupMenuItem(value: 'user', child: Text('User')),
                    ],
                  ),
                ],
              ),
              if (_selectedRole != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Chip(
                    label: Text('Filter: $_selectedRole'),
                    onDeleted: () {
                      setState(() => _selectedRole = null);
                      _loadUsers();
                    },
                  ),
                ),
            ],
          ),
        ),
        
        // Users List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Tidak ada pengguna', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return _buildUserCard(user);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildUserCard(dynamic user) {
    final role = user['role']?.toString() ?? 'user';
    final isVerified = user['is_user_verified'] == true || user['is_user_verified'] == 1;
    final isEmailVerified = user['is_email_verified'] == true || user['is_email_verified'] == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: role == 'admin' ? Colors.red : Colors.blue,
          child: Text(
            user['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user['name'] ?? 'No Name',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user['email'] ?? ''),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: role == 'admin' ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: role == 'admin' ? Colors.red : Colors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isVerified)
                  const Icon(Icons.verified_user, size: 16, color: Colors.green),
                if (isEmailVerified)
                  const Icon(Icons.verified, size: 16, color: Colors.blue),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'verify':
                _verifyUser(user['id']);
                break;
              case 'make_admin':
                _changeRole(user['id'], 'admin');
                break;
              case 'make_user':
                _changeRole(user['id'], 'user');
                break;
            }
          },
          itemBuilder: (context) => [
            if (!isVerified)
              const PopupMenuItem(value: 'verify', child: Text('Verifikasi User')),
            if (role != 'admin')
              const PopupMenuItem(value: 'make_admin', child: Text('Jadikan Admin')),
            if (role == 'admin')
              const PopupMenuItem(value: 'make_user', child: Text('Jadikan User')),
            const PopupMenuItem(value: 'view', child: Text('Lihat Detail')),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

// Tab: Announcements Management
class AdminAnnouncementsTab extends StatefulWidget {
  const AdminAnnouncementsTab({super.key});

  @override
  State<AdminAnnouncementsTab> createState() => _AdminAnnouncementsTabState();
}

class _AdminAnnouncementsTabState extends State<AdminAnnouncementsTab> with AutomaticKeepAliveClientMixin {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _announcements = [];
  bool _isLoading = false;
  String? _selectedStatus;
  String _searchQuery = '';
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _adminService.getAnnouncements(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _selectedStatus,
      );
      
      setState(() {
        _announcements = response['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
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
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari pengumuman...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        
        // Announcements List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _announcements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.announcement_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Tidak ada pengumuman', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAnnouncements,
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
    final priority = announcement['priority']?.toString().toLowerCase() ?? 'normal';
    
    Color priorityColor;
    switch (priority) {
      case 'urgent':
        priorityColor = Colors.red;
        break;
      case 'high':
        priorityColor = Colors.orange;
        break;
      case 'normal':
        priorityColor = Colors.blue;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          isSticky ? Icons.push_pin : Icons.announcement,
          color: isSticky ? Colors.red : null,
        ),
        title: Text(
          announcement['title'] ?? 'No Title',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              announcement['summary'] ?? announcement['content'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'AKTIF' : 'NONAKTIF',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'toggle_status':
                _toggleStatus(announcement['id']);
                break;
              case 'publish':
                _publishAnnouncement(announcement['id']);
                break;
              case 'view':
                // TODO: Show detail
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('Lihat Detail')),
            PopupMenuItem(
              value: 'toggle_status',
              child: Text(isActive ? 'Nonaktifkan' : 'Aktifkan'),
            ),
            if (!isActive)
              const PopupMenuItem(value: 'publish', child: Text('Publikasi')),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

