import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../routes/app_router.dart';
import '../complaints/complaint_list_screen.dart';
import '../announcements/announcement_list_screen.dart' hide Announcement;
import '../announcements/announcement_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../categories/popular_categories_screen.dart';

// ─── HomeScreen ───────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ComplaintListScreen(),
    const AnnouncementListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_create_complaint',
          onPressed: () {
            final user = Provider.of<AuthProvider>(context, listen: false).user;
            if (user != null && !user.isUserVerified) {
              _showUnverifiedDialog(context);
              return;
            }
            context.push(AppRouter.createComplaint);
          },
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 32),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _NavItem(icon: Icons.home_rounded, outlinedIcon: Icons.home_outlined, label: 'Beranda', index: 0, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
            _NavItem(icon: Icons.history_rounded, outlinedIcon: Icons.history_outlined, label: 'Riwayat', index: 1, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
            const Expanded(child: SizedBox()), // FAB notch space
            _NavItem(icon: Icons.campaign_rounded, outlinedIcon: Icons.campaign_outlined, label: 'Pengumuman', index: 2, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
            _NavItem(icon: Icons.person_rounded, outlinedIcon: Icons.person_outline_rounded, label: 'Akun', index: 3, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
          ],
        ),
      ),
    );
  }

  void _showUnverifiedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C)),
            const SizedBox(width: 8),
            Expanded(child: Text('Akun Belum Terverifikasi', style: GoogleFonts.nunito(fontWeight: FontWeight.w700))),
          ],
        ),
        content: Text(
          'KTP Anda sedang menunggu verifikasi dari admin. Anda baru dapat membuat pengaduan setelah akun diverifikasi.',
          style: GoogleFonts.nunito(height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text('Mengerti', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── NavItem ──────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? icon : outlinedIcon,
                color: selected ? AppTheme.primary : Colors.grey.shade400, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppTheme.primary : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DashboardScreen ──────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _hasLoadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _loadData();
      });
    }
  }

  Future<void> _loadData() async {
    final cp = Provider.of<ComplaintProvider>(context, listen: false);
    final np = Provider.of<NotificationProvider>(context, listen: false);
    final ap = Provider.of<AnnouncementProvider>(context, listen: false);
    await Future.wait([
      cp.loadStatistics(),
      np.loadNotifications(refresh: true),
      ap.loadPublicAnnouncements(),
    ]);
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi,';
    if (h < 15) return 'Selamat Siang,';
    if (h < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  String _monthName(int month) {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return names[month];
  }

  int _waitingCount(Map<String, dynamic>? stats) {
    if (stats == null) return 0;
    for (final key in ['waiting_user_confirmation', 'waiting_user_confirmations', 'waiting_confirmation', 'waitingUserConfirmation']) {
      final v = stats[key];
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cp   = Provider.of<ComplaintProvider>(context);
    final np   = Provider.of<NotificationProvider>(context);
    final waiting = _waitingCount(cp.statistics);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 210,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.bgDark,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background map image
                    Image.network(
                      'https://bleuglaciotrip.co.in/wp-content/uploads/2025/05/INDONESIA.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppTheme.bgDark),
                    ),
                    // Dark overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.bgDark.withValues(alpha: 0.75),
                            AppTheme.bgDark.withValues(alpha: 0.92),
                          ],
                        ),
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _getGreeting(),
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              auth.user?.name ?? 'User',
                              style: GoogleFonts.nunito(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sampaikan keluhan Anda untuk Indonesia yang lebih baik.',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.75),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Pinned app bar content
              title: Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text('MyPengaduan',
                      style: GoogleFonts.nunito(
                          fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
              titleSpacing: 16,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                        onPressed: () => context.push(AppRouter.notifications),
                      ),
                      if (np.unreadCount > 0)
                        Positioned(
                          right: 8, top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              np.unreadCount > 99 ? '99+' : '${np.unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Content ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alert konfirmasi
                    if (waiting > 0) ...[
                      _buildWaitingAlert(context, waiting),
                      const SizedBox(height: 24),
                    ],

                    // Pengumuman Terbaru
                    _buildSectionHeader('Pengumuman Terbaru',
                        onTap: () => context.push(AppRouter.announcementsList)),
                    const SizedBox(height: 12),
                    _buildAnnouncementCarousel(context),
                    const SizedBox(height: 28),

                    // Aksi Cepat
                    _buildSectionTitle('Aksi Cepat'),
                    const SizedBox(height: 12),
                    _buildQuickActions(context),
                    const SizedBox(height: 28),

                    // Kategori Keluhan Populer
                    _buildSectionHeader('Kategori Keluhan Populer',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const PopularCategoriesScreen()))),
                    const SizedBox(height: 12),
                    _buildCategoryChips(context),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section header dengan "Lihat Semua" ──────────────────────
  Widget _buildSectionHeader(String title, {required VoidCallback onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.nunito(
                fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Lihat Semua',
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.nunito(
            fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary));
  }

  // ── Alert konfirmasi penyelesaian ─────────────────────────────
  Widget _buildWaitingAlert(BuildContext context, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEA580C).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fact_check_rounded, color: Color(0xFFEA580C), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Konfirmasi Penyelesaian Dibutuhkan',
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF9A3412))),
                const SizedBox(height: 4),
                Text(
                  'Ada $count pengaduan yang sudah ditangani dan menunggu konfirmasi Anda.',
                  style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF9A3412), height: 1.4),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => context.push(AppRouter.myComplaints),
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: Text('Lihat Pengaduan', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Carousel pengumuman ───────────────────────────────────────
  Widget _buildAnnouncementCarousel(BuildContext context) {
    return Consumer<AnnouncementProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.homeAnnouncements.isEmpty) {
          return SizedBox(
            height: 145,
            child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          );
        }
        if (provider.homeAnnouncements.isEmpty) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Center(
              child: Text('Belum ada pengumuman',
                  style: GoogleFonts.nunito(color: AppTheme.textSecondary)),
            ),
          );
        }

        final items = provider.homeAnnouncements.take(5).toList();
        final gradientSets = [
          [AppTheme.bgDark, AppTheme.secondary],
          [AppTheme.secondary, AppTheme.primaryDark],
          [AppTheme.primaryDark, const Color(0xFF1B5E20)],
        ];

        return SizedBox(
          height: 145,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final item = items[index];
              final gradient = gradientSets[index % gradientSets.length];
              final imageUrl = item.coverImage?.isNotEmpty == true
                  ? item.coverImage
                  : (item.attachments?.isNotEmpty == true ? item.attachments!.first : null);
              final date = item.publishedAt != null
                  ? '${item.publishedAt!.day} ${_monthName(item.publishedAt!.month)} ${item.publishedAt!.year}'
                  : '';

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnnouncementDetailScreen(announcement: item),
                  ),
                ),
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient.cast<Color>(),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Network image jika tersedia
                      if (imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(imageUrl,
                              width: 180,
                              height: 145,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox()),
                        ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.80),
                            ],
                          ),
                        ),
                      ),
                      // Text overlay — pakai Positioned agar tidak overflow
                      Positioned(
                        bottom: 10, left: 10, right: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.nunito(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (date.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(date,
                                  style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: 0.75))),
                            ],
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
      },
    );
  }

  // ── Grid aksi cepat 3×2 ───────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.add_circle_rounded,
        label: 'Lapor\nKeluhan',
        color: AppTheme.primary,
        onTap: () {
          final user = Provider.of<AuthProvider>(context, listen: false).user;
          if (user != null && !user.isUserVerified) {
            _showUnverifiedDialog(context);
            return;
          }
          context.push(AppRouter.createComplaint);
        },
      ),
      _QuickAction(
        icon: Icons.manage_search_rounded,
        label: 'Cek\nStatus',
        color: AppTheme.secondary,
        onTap: () => context.push(AppRouter.myComplaints),
      ),
      _QuickAction(
        icon: Icons.list_alt_rounded,
        label: 'Pengaduan\nSaya',
        color: AppTheme.primaryDark,
        onTap: () => context.push(AppRouter.myComplaints),
      ),
      _QuickAction(
        icon: Icons.help_outline_rounded,
        label: 'FAQ',
        color: AppTheme.accent,
        onTap: () => context.push(AppRouter.faq),
      ),
      _QuickAction(
        icon: Icons.campaign_rounded,
        label: 'Informasi\nPublik',
        color: AppTheme.primary,
        onTap: () => context.push(AppRouter.announcementsList),
      ),
      _QuickAction(
        icon: Icons.phone_rounded,
        label: 'Hubungi\nKami',
        color: AppTheme.secondary,
        onTap: () => context.push(AppRouter.contact),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: actions.map(_buildActionItem).toList(),
    );
  }

  Widget _buildActionItem(_QuickAction a) {
    return GestureDetector(
      onTap: a.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: a.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(a.icon, color: a.color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            a.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Kategori cards ─────────────────────────────────────────────
  Widget _buildCategoryChips(BuildContext context) {
    final categories = [
      _CategoryItem(icon: Icons.construction_rounded,       label: 'Jalan &\nInfrastruktur', color: AppTheme.primary),
      _CategoryItem(icon: Icons.cleaning_services_rounded,  label: 'Kebersihan',              color: AppTheme.secondary),
      _CategoryItem(icon: Icons.assignment_rounded,         label: 'Perizinan',               color: AppTheme.primaryDark),
      _CategoryItem(icon: Icons.category_rounded,           label: 'Lainnya',                 color: AppTheme.accent),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          return GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PopularCategoriesScreen())),
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cat.color.withValues(alpha: 0.25), width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cat.color,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showUnverifiedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Akun Belum Terverifikasi',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Text(
          'KTP Anda sedang menunggu verifikasi dari admin. Anda baru dapat membuat pengaduan setelah akun diverifikasi.',
          style: GoogleFonts.nunito(height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text('Mengerti', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

}

// ─── Data class untuk quick action ───────────────────────────────────────────
class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
}

// ─── Data class untuk category item ──────────────────────────────────────────
class _CategoryItem {
  final IconData icon;
  final String label;
  final Color color;
  const _CategoryItem({required this.icon, required this.label, required this.color});
}
