import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';
import '../../../widgets/skeleton_loader.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> with AutomaticKeepAliveClientMixin {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  
  // Static cache for global state persistence
  static bool _hasLoadedDataGlobally = false;
  static List<dynamic> _cachedUsers = [];
  
  List<dynamic> _users = [];
  bool _isLoading = false;
  bool _hasLoadedData = false;
  String? _selectedRole;
  String _searchQuery = '';
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print('👥 [AdminUsersTab] Screen initialized - will load after visible');
    
    // Use cached data if available
    if (_hasLoadedDataGlobally && _cachedUsers.isNotEmpty) {
      debugPrint('👥 [AdminUsersTab] Using cached data (${_cachedUsers.length} items)');
      _users = _cachedUsers;
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
          print('👥 [AdminUsersTab] Screen visible - loading users now');
          _loadUsers();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool forceRefresh = false}) async {
    // Skip loading if already loaded globally and not forcing refresh
    if (_hasLoadedDataGlobally && !forceRefresh) {
      debugPrint('Admin Users: Already loaded globally, skipping...');
      return;
    }
    
    debugPrint('Admin Users: Loading users... (forceRefresh: $forceRefresh)');
    if (forceRefresh) {
      setState(() => _isLoading = true);
    }
    
    try {
      final response = await _adminService.getUsers(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        role: _selectedRole,
        perPage: 10,
      );
      
      if (mounted) {
        setState(() {
          _users = response['data'] ?? [];
          _cachedUsers = _users; // Update cache
          _hasLoadedDataGlobally = true; // Mark as loaded globally
          _isLoading = false;
          _hasLoadedData = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (forceRefresh) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
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
          child: !_hasLoadedData
              ? ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: 5,
                  itemBuilder: (context, index) => const ListItemSkeleton(),
                )
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
                      onRefresh: () => _loadUsers(forceRefresh: true),
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
    final roleColor = role == 'admin' ? Colors.red : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: roleColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showUserDetailDialog(user);
        },
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Hero(
              tag: 'user_${user['id']}',
              child: CircleAvatar(
                radius: 30,
                backgroundColor: roleColor,
                child: Text(
                  user['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user['name'] ?? 'No Name',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified_user, size: 16, color: Colors.green),
                        ),
                      if (isEmailVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified, size: 16, color: Colors.blue),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['email'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
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
                  case 'view':
                    _showUserDetailDialog(user);
                    break;
                }
              },
              itemBuilder: (context) => [
                if (!isVerified)
                  const PopupMenuItem(
                    value: 'verify',
                    child: Row(
                      children: [
                        Icon(Icons.verified_user, size: 18, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Verifikasi User'),
                      ],
                    ),
                  ),
                if (role != 'admin')
                  const PopupMenuItem(
                    value: 'make_admin',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Jadikan Admin'),
                      ],
                    ),
                  ),
                if (role == 'admin')
                  const PopupMenuItem(
                    value: 'make_user',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Jadikan User'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 8),
                      Text('Lihat Detail'),
                    ],
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showUserDetailDialog(dynamic user) {
    final isVerified = user['is_user_verified'] == true || user['is_user_verified'] == 1;
    final isEmailVerified = user['is_email_verified'] == true || user['is_email_verified'] == 1;
    final role = user['role']?.toString() ?? 'user';
    final roleColor = role == 'admin' ? Colors.red : Colors.blue;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: roleColor,
                      child: Text(
                        user['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'] ?? 'No Name',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 32),
                
                _buildDetailRow(Icons.email, 'Email', user['email'] ?? '-'),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.phone, 'Telepon', user['phone'] ?? '-'),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.location_on, 'Alamat', user['address'] ?? '-'),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.badge, 'NIK', user['nik'] ?? '-'),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.home, 'RT/RW', 
                  user['rt_number'] != null && user['rw_number'] != null 
                    ? 'RT ${user['rt_number']} / RW ${user['rw_number']}'
                    : '-'),
                const SizedBox(height: 16),
                
                // Status Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusChip(
                      isVerified ? 'User Terverifikasi' : 'Belum Terverifikasi',
                      isVerified ? Colors.green : Colors.orange,
                      isVerified ? Icons.check_circle : Icons.warning,
                    ),
                    _buildStatusChip(
                      isEmailVerified ? 'Email Terverifikasi' : 'Email Belum Terverifikasi',
                      isEmailVerified ? Colors.green : Colors.orange,
                      isEmailVerified ? Icons.email : Icons.email_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Complaint count
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.report_problem, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Text(
                        'Total Pengaduan: ${user['complaints_count'] ?? 0}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isVerified)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _verifyUser(user['id']);
                        },
                        icon: const Icon(Icons.verified_user),
                        label: const Text('Verifikasi'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}
