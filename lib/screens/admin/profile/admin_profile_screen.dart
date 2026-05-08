import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/complaint_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/announcement_provider.dart';
import '../../../models/user_model.dart';
import '../../../routes/app_router.dart';
import '../../../theme/app_theme.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    await context.read<AuthProvider>().getProfile();
  }

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppTheme.danger, size: 32),
              ),
              const SizedBox(height: 16),
              Text('Keluar dari Akun?',
                  style: GoogleFonts.nunito(
                      fontSize: 17, fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text('Anda akan keluar dari sesi admin ini.',
                  style: GoogleFonts.nunito(
                      fontSize: 13, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppTheme.border),
                        foregroundColor: AppTheme.textSecondary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Batal',
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Keluar',
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      final auth = context.read<AuthProvider>();
      try { context.read<ComplaintProvider>().clear(); } catch (_) {}
      try { context.read<NotificationProvider>().clear(); } catch (_) {}
      try { context.read<AnnouncementProvider>().clear(); } catch (_) {}
      await auth.logout();
      if (mounted) context.go(AppRouter.landing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_rounded,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Tidak ada data profil',
                      style: GoogleFonts.nunito(
                          fontSize: 16, color: AppTheme.textSecondary)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _loadProfile,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text('Muat Ulang',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                  ),
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
                        _buildSectionLabel('Informasi Akun'),
                        const SizedBox(height: 8),
                        _buildInfoCard([
                          _InfoRow(Icons.email_rounded, 'Email', user.email),
                          _InfoRow(Icons.phone_rounded, 'No. Telepon',
                              user.phone ?? 'Belum diatur'),
                        ]),
                        const SizedBox(height: 20),
                        _buildSectionLabel('Informasi Pribadi'),
                        const SizedBox(height: 8),
                        _buildInfoCard([
                          _InfoRow(Icons.badge_rounded, 'NIK',
                              user.nik ?? 'Belum diatur'),
                          _InfoRow(Icons.home_rounded, 'Alamat',
                              user.address ?? 'Belum diatur'),
                          _InfoRow(
                            Icons.location_city_rounded,
                            'RT / RW',
                            (user.rtNumber != null && user.rwNumber != null)
                                ? 'RT ${user.rtNumber} / RW ${user.rwNumber}'
                                : 'Belum diatur',
                          ),
                        ]),
                        const SizedBox(height: 20),
                        _buildSectionLabel('Status Akun'),
                        const SizedBox(height: 8),
                        _buildStatusCard(user),
                        const SizedBox(height: 28),
                        _buildActions(user),
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

  // ── Header dark forest green ────────────────────────────────────
  Widget _buildHeader(User user) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.bgDeep, AppTheme.bgDark],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
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
                          color: AppTheme.primary.withValues(alpha: 0.45),
                          blurRadius: 20, spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'A',
                        style: GoogleFonts.nunito(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  // Admin badge
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.bgDark, width: 2),
                      ),
                      child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Name
              Text(user.name,
                  style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              // Email
              Text(user.email,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.72)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 14),
              // Badges
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8, runSpacing: 6,
                children: [
                  _badge('ADMIN', const Color(0xFF6366F1),
                      icon: Icons.admin_panel_settings_rounded),
                  if (user.isUserVerified)
                    _badge('Terverifikasi', AppTheme.primaryLight,
                        icon: Icons.verified_rounded)
                  else
                    _badge('Belum Terverifikasi', AppTheme.warning,
                        icon: Icons.pending_rounded),
                ],
              ),
            ],
          ),
        ),
        // Leaf decorations
        Positioned(
          top: 60, right: 16,
          child: Transform.rotate(
            angle: 0.3,
            child: Icon(Icons.eco_rounded, size: 40,
                color: AppTheme.primaryDark.withValues(alpha: 0.4)),
          ),
        ),
        Positioned(
          top: 80, left: 12,
          child: Transform.rotate(
            angle: -0.5,
            child: Icon(Icons.eco_rounded, size: 28,
                color: AppTheme.primaryDark.withValues(alpha: 0.35)),
          ),
        ),
        // Settings icon
        Positioned(
          top: 48,
          right: 8,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.settings_rounded,
                  color: Colors.white70, size: 22),
              onPressed: () {},
            ),
          ),
        ),
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
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
          style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary)),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              _buildInfoTile(e.value),
              if (!isLast)
                Divider(
                    height: 1, indent: 56, endIndent: 16,
                    color: AppTheme.border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoTile(_InfoRow row) {
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
            child: Icon(row.icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.label,
                    style: GoogleFonts.nunito(
                        fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(row.value,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(User user) {
    final verified = user.isUserVerified;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Verification status
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: verified
                      ? AppTheme.primary.withValues(alpha: 0.08)
                      : AppTheme.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: verified
                        ? AppTheme.primary.withValues(alpha: 0.25)
                        : AppTheme.warning.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      verified
                          ? Icons.check_circle_rounded
                          : Icons.pending_rounded,
                      size: 16,
                      color: verified ? AppTheme.primary : AppTheme.warning,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        verified ? 'Terverifikasi' : 'Belum Verifikasi',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: verified
                              ? AppTheme.primary
                              : AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Join date
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bergabung',
                        style: GoogleFonts.nunito(
                            fontSize: 11, color: AppTheme.textSecondary)),
                    const SizedBox(height: 2),
                    Text(_formatDate(user.createdAt),
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(User user) {
    return Column(
      children: [
        // Edit Profile
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EditAdminProfileScreen(user: user)),
            ).then((_) => _loadProfile()),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text('Edit Profil',
                style: GoogleFonts.nunito(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Logout
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: Icon(Icons.logout_rounded,
                size: 18, color: AppTheme.danger),
            label: Text('Keluar',
                style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.danger)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
}
