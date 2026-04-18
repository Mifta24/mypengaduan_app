import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/complaint_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/announcement_provider.dart';
import '../../../models/user_model.dart';
import '../../../routes/app_router.dart';
import 'edit_admin_profile_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.getProfile();
  }

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      
      // Clear all provider states before logout
      try {
        context.read<ComplaintProvider>().clear();
      } catch (e) {
        print('ComplaintProvider not available: $e');
      }
      try {
        context.read<NotificationProvider>().clear();
      } catch (e) {
        print('NotificationProvider not available: $e');
      }
      try {
        context.read<AnnouncementProvider>().clear();
      } catch (e) {
        print('AnnouncementProvider not available: $e');
      }
      
      await authProvider.logout();
      if (mounted) {
        context.go(AppRouter.landing);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Admin'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tidak ada data profil',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProfile,
                    child: const Text('Muat Ulang'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header with gradient background
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // Profile Picture
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 56,
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  user.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Name
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user.role.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  
                  // Profile Information Cards
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Account Information
                        _buildSectionCard(
                          title: 'Informasi Akun',
                          icon: Icons.account_circle,
                          children: [
                            _buildInfoTile(
                              icon: Icons.email,
                              label: 'Email',
                              value: user.email,
                            ),
                            _buildInfoTile(
                              icon: Icons.phone,
                              label: 'No. Telepon',
                              value: user.phone ?? '-',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Personal Information
                        _buildSectionCard(
                          title: 'Informasi Pribadi',
                          icon: Icons.person,
                          children: [
                            _buildInfoTile(
                              icon: Icons.badge,
                              label: 'NIK',
                              value: user.nik ?? '-',
                            ),
                            _buildInfoTile(
                              icon: Icons.home,
                              label: 'Alamat',
                              value: user.address ?? '-',
                            ),
                            _buildInfoTile(
                              icon: Icons.location_city,
                              label: 'RT/RW',
                              value: user.rtNumber != null && user.rwNumber != null
                                  ? 'RT ${user.rtNumber}/RW ${user.rwNumber}'
                                  : '-',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Account Status
                        _buildSectionCard(
                          title: 'Status Akun',
                          icon: Icons.verified,
                          children: [
                            _buildInfoTile(
                              icon: Icons.check_circle,
                              label: 'Status Verifikasi',
                              value: user.isUserVerified ? 'Terverifikasi' : 'Belum Terverifikasi',
                              valueColor: user.isUserVerified ? Colors.green : Colors.orange,
                            ),
                            _buildInfoTile(
                              icon: Icons.calendar_today,
                              label: 'Bergabung Sejak',
                              value: _formatDate(user.createdAt),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Action Buttons
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditAdminProfileScreen(user: user),
                                    ),
                                  ).then((_) => _loadProfile());
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Profil'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _confirmLogout,
                                icon: const Icon(Icons.logout, color: Colors.red),
                                label: const Text(
                                  'Logout',
                                  style: TextStyle(color: Colors.red),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
