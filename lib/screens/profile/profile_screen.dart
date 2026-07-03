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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.user == null && auth.isAuthenticated) {
        auth.getProfile();
      }
    });
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    await context.read<AuthProvider>().getProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null && auth.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Tidak ada data profil',
                      style: GoogleFonts.nunito(fontSize: 16, color: AppTheme.textSecondary)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _loadProfile,
            color: AppTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(user),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    child: Column(
                      children: [
                        _buildInfoCard(user),
                        const SizedBox(height: 20),
                        _buildSettingsCard(context, user),
                        const SizedBox(height: 20),
                        _buildLogoutButton(context),
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

  // ── Header dark green ──────────────────────────────────────────
  Widget _buildHeader(User user) {
    return Stack(
      children: [
        // Background
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.bgDeep, AppTheme.bgDark],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
          child: Column(
            children: [
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 20, spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: user.avatar != null
                          ? Image.network(
                              user.avatar!,
                              width: 90, height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.nunito(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'U',
                                style: GoogleFonts.nunito(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                              ),
                            ),
                    ),
                  ),
                  // Verified badge
                  if (user.isUserVerified)
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.bgDark, width: 2),
                        ),
                        child: const Icon(Icons.check, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Name
              Text(user.name,
                  style: GoogleFonts.nunito(
                      fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              // Email
              Text(user.email,
                  style: GoogleFonts.nunito(
                      fontSize: 13, color: Colors.white.withValues(alpha: 0.75)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              // Badges row
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8, runSpacing: 6,
                children: [
                  _badge(user.role == 'admin' ? 'Admin' : 'Warga',
                      user.role == 'admin' ? const Color(0xFF6366F1) : AppTheme.primaryLight),
                  if (user.isUserVerified)
                    _badge('Terverifikasi', AppTheme.primary,
                        icon: Icons.verified_rounded),
                  if (!user.isUserVerified)
                    _badge('Belum Terverifikasi', const Color(0xFFD97706),
                        icon: Icons.pending_rounded),
                ],
              ),
            ],
          ),
        ),
        // Leaf decorations
        Positioned(top: 60, right: 16,
            child: Transform.rotate(angle: 0.3,
                child: Icon(Icons.eco_rounded, size: 40,
                    color: AppTheme.primaryDark.withValues(alpha: 0.4)))),
        Positioned(top: 80, left: 12,
            child: Transform.rotate(angle: -0.5,
                child: Icon(Icons.eco_rounded, size: 28,
                    color: AppTheme.primaryDark.withValues(alpha: 0.35)))),
      ],
    );
  }

  Widget _badge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }

  // ── Informasi Pribadi ──────────────────────────────────────────
  Widget _buildInfoCard(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informasi Pribadi',
            style: GoogleFonts.nunito(
                fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              _infoTile(Icons.phone_rounded, 'Nomor Telepon', user.phone ?? 'Belum diatur'),
              _divider(),
              _infoTile(Icons.location_on_rounded, 'Alamat', user.address ?? 'Belum diatur'),
              if (user.nik?.isNotEmpty == true) ...[
                _divider(),
                _infoTile(Icons.credit_card_rounded, 'NIK', user.nik!),
              ],
              if (user.rtNumber != null || user.rwNumber != null) ...[
                _divider(),
                _infoTile(Icons.home_work_rounded, 'RT / RW',
                    'RT ${user.rtNumber ?? '-'} / RW ${user.rwNumber ?? '-'}'),
              ],
              _divider(),
              _infoTile(Icons.calendar_today_rounded, 'Bergabung Sejak',
                  _fmt(user.createdAt)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.nunito(
                        fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pengaturan Akun ────────────────────────────────────────────
  Widget _buildSettingsCard(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pengaturan Akun',
            style: GoogleFonts.nunito(
                fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              _actionTile(
                context,
                icon: Icons.edit_rounded,
                label: 'Edit Profil',
                onTap: () => context.push(AppRouter.editProfile)
                    .then((r) { if (r == true) _loadProfile(); }),
              ),
              _divider(),
              _divider(),
              _actionTile(
                context,
                icon: Icons.lock_rounded,
                label: 'Ubah Password',
                onTap: () => context.push(AppRouter.changePassword),
              ),
              _divider(),
              _actionTile(
                context,
                icon: Icons.notifications_outlined,
                label: 'Pengaturan Notifikasi',
                onTap: () => context.push(AppRouter.notificationSettings),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionTile(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Icon(icon, size: 18, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ── Tombol Logout ──────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
        label: Text('Keluar',
            style: GoogleFonts.nunito(
                fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444))),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFEF4444)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFFFEF2F2),
        ),
      ),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 64, color: AppTheme.border);

  void _showLogoutDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Konfirmasi Keluar',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        content: Text('Apakah Anda yakin ingin keluar dari aplikasi?',
            style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('Batal', style: GoogleFonts.nunito()),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              try { ctx.read<ComplaintProvider>().clear(); } catch (_) {}
              try { ctx.read<NotificationProvider>().clear(); } catch (_) {}
              try { ctx.read<AnnouncementProvider>().clear(); } catch (_) {}
              final authProvider = ctx.read<AuthProvider>();
              await authProvider.logout();
              if (mounted && ctx.mounted) ctx.go(AppRouter.landing);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Keluar', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}
