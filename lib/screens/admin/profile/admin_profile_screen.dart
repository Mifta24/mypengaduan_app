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

class _AdminProfileScreenState extends State<AdminProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _gradientStart = Color(0xFF1A237E);
  static const _gradientEnd = Color(0xFF3949AB);
  static const _accentColor = Color(0xFF5C6BC0);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded,
                    color: Colors.red.shade600, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Keluar dari Akun?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Anda akan keluar dari sesi admin ini.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Keluar'),
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
      final authProvider = context.read<AuthProvider>();
      try { context.read<ComplaintProvider>().clear(); } catch (_) {}
      try { context.read<NotificationProvider>().clear(); } catch (_) {}
      try { context.read<AnnouncementProvider>().clear(); } catch (_) {}
      await authProvider.logout();
      if (mounted) context.go(AppRouter.landing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          if (user == null) {
            return _buildEmptyState();
          }

          return FadeTransition(
            opacity: _fadeAnim,
            child: RefreshIndicator(
              onRefresh: _loadProfile,
              color: _gradientEnd,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildSliverHeader(user),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildInfoCard(
                            title: 'Informasi Akun',
                            icon: Icons.manage_accounts_rounded,
                            items: [
                              _InfoItem(Icons.email_rounded, 'Email', user.email),
                              _InfoItem(Icons.phone_rounded, 'No. Telepon',
                                  user.phone ?? '-'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            title: 'Informasi Pribadi',
                            icon: Icons.person_rounded,
                            items: [
                              _InfoItem(Icons.badge_rounded, 'NIK',
                                  user.nik ?? '-'),
                              _InfoItem(Icons.home_rounded, 'Alamat',
                                  user.address ?? '-'),
                              _InfoItem(
                                Icons.location_city_rounded,
                                'RT / RW',
                                user.rtNumber != null && user.rwNumber != null
                                    ? 'RT ${user.rtNumber}  /  RW ${user.rwNumber}'
                                    : '-',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStatusCard(user),
                          const SizedBox(height: 28),
                          _buildActionButtons(user),
                        ],
                      ),
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

  Widget _buildSliverHeader(User user) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStart, _gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // AppBar area
            SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Profil Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded,
                          color: Colors.white70),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditAdminProfileScreen(user: user)),
                      ).then((_) => _loadProfile()),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: _accentColor.withValues(alpha: 0.15),
                      child: Text(
                        user.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: _gradientEnd,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 16),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Name
            Text(
              user.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),

            // Email
            Text(
              user.email,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),

            // Role badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user_rounded,
                      color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    user.role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Curved bottom
            ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                height: 36,
                color: const Color(0xFFF5F6FA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<_InfoItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _gradientEnd.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _gradientEnd, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // Items
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            final item = entry.value;
            return Column(
              children: [
                _buildTile(item),
                if (!isLast)
                  const Divider(height: 1, indent: 52, endIndent: 16),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTile(_InfoItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 16, color: _accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(User user) {
    final isVerified = user.isUserVerified;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _gradientEnd.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_rounded,
                      color: _gradientEnd, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Status Akun',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Verification status
                Expanded(
                  child: _buildStatusChip(
                    icon: isVerified
                        ? Icons.check_circle_rounded
                        : Icons.pending_rounded,
                    label: isVerified ? 'Terverifikasi' : 'Belum Verifikasi',
                    color: isVerified
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFF57F17),
                    bgColor: isVerified
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF8E1),
                  ),
                ),
                const SizedBox(width: 12),
                // Join date
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bergabung',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(user.createdAt),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(User user) {
    return Column(
      children: [
        // Edit Profile
        SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_gradientStart, _gradientEnd],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _gradientEnd.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EditAdminProfileScreen(user: user)),
              ).then((_) => _loadProfile()),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text(
                'Edit Profil',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Logout
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text(
              'Keluar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              side: BorderSide(color: Colors.red.shade300, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Tidak ada data profil',
              style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Muat Ulang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gradientEnd,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.quadraticBezierTo(
        size.width / 2, size.height * 1.8, size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}
