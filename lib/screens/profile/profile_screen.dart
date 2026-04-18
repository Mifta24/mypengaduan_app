import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../models/user_model.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _loadProfile() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.getProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;

          if (user == null) {
            // User logged out or data not available
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 80,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                   Text(
                    'Tidak ada data profil',
                    style: GoogleFonts.nunito(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan login untuk melihat profil',
                    style: GoogleFonts.nunito(color: AppTheme.textSecondary),
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
                  _buildHeader(user),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildProfileInfo(user),
                        const SizedBox(height: 24),
                        _buildActionSettings(context),
                        const SizedBox(height: 40),
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

  Widget _buildHeader(User user) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15803D), AppTheme.primary, AppTheme.secondary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
      child: Column(
        children: [
          Text(
            'Profil Saya',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 46,
              backgroundColor: AppTheme.surface,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: GoogleFonts.nunito(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge(
                label: user.role.toUpperCase(),
                color: user.role == 'admin' ? const Color(0xFFEF4444) : Colors.white.withOpacity(0.2),
                textColor: Colors.white,
              ),
              const SizedBox(width: 8),
              if (user.isEmailVerified)
                _buildBadge(
                  label: 'Email Verified',
                  color: Colors.white.withOpacity(0.2),
                  textColor: Colors.white,
                  icon: Icons.verified,
                ),
              const SizedBox(width: 8),
              if (user.isUserVerified)
                _buildBadge(
                  label: 'User Verified',
                  color: Colors.white.withOpacity(0.2),
                  textColor: Colors.white,
                  icon: Icons.verified_user,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            'Informasi Pribadi',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildInfoTile(Icons.phone, 'Nomor Telepon', user.phone ?? 'Belum diatur'),
              const Divider(height: 1, indent: 56, color: AppTheme.border),
              _buildInfoTile(Icons.location_on, 'Alamat Lengkap', user.address ?? 'Belum diatur'),
              if (user.nik != null) ...[
                const Divider(height: 1, indent: 56, color: AppTheme.border),
                _buildInfoTile(Icons.credit_card, 'NIK', user.nik!),
              ],
              if (user.rtNumber != null || user.rwNumber != null) ...[
                const Divider(height: 1, indent: 56, color: AppTheme.border),
                _buildInfoTile(
                  Icons.home_work,
                  'Lingkungan',
                  'RT ${user.rtNumber ?? '-'} / RW ${user.rwNumber ?? '-'}',
                ),
              ],
              const Divider(height: 1, indent: 56, color: AppTheme.border),
              _buildInfoTile(
                Icons.calendar_today,
                'Bergabung Sejak',
                _formatDate(user.createdAt),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppTheme.primary),
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildActionSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            'Pengaturan Akun',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActionTile(
                icon: Icons.edit_outlined,
                title: 'Edit Profil',
                onTap: () => context.push(AppRouter.editProfile).then((result) {
                  if (result == true) {
                    _loadProfile();
                  }
                }),
              ),
              const Divider(height: 1, indent: 56, color: AppTheme.border),
              _buildActionTile(
                icon: Icons.lock_outline,
                title: 'Ubah Password',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56, color: AppTheme.border),
              _buildActionTile(
                icon: Icons.logout,
                title: 'Keluar',
                isDestructive: true,
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFEF4444) : AppTheme.textPrimary;
    final iconColor = isDestructive ? const Color(0xFFEF4444) : AppTheme.textSecondary;
    
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? color.withOpacity(0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
    );
  }

  void _showLogoutDialog(BuildContext outerContext) {
    showDialog(
      context: outerContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final authProvider = outerContext.read<AuthProvider>();
                
                // Clear all provider states before logout
                try {
                  outerContext.read<ComplaintProvider>().clear();
                } catch (e) {
                  print('ComplaintProvider not available: $e');
                }
                try {
                  outerContext.read<NotificationProvider>().clear();
                } catch (e) {
                  print('NotificationProvider not available: $e');
                }
                try {
                  outerContext.read<AnnouncementProvider>().clear();
                } catch (e) {
                  print('AnnouncementProvider not available: $e');
                }
                
                await authProvider.logout();
                if (mounted) {
                  outerContext.go(AppRouter.landing);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
