import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'widgets/dashboard_widgets.dart';

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

  int _waitingCount(Map<String, dynamic>? stats) {
    if (stats == null) return 0;
    for (final key in [
      'waiting_user_confirmation',
      'waiting_user_confirmations',
      'waiting_confirmation',
      'waitingUserConfirmation',
    ]) {
      final v = stats[key];
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth    = Provider.of<AuthProvider>(context);
    final cp      = Provider.of<ComplaintProvider>(context);
    final np      = Provider.of<NotificationProvider>(context);
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
                    Image.network(
                      'https://bleuglaciotrip.co.in/wp-content/uploads/2025/05/INDONESIA.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppTheme.bgDark),
                    ),
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
                              'Sampaikan keluhan Anda untuk Lingkungan yang lebih baik.',
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
              title: Row(
                children: [
                  const Icon(Icons.campaign_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text('MyPengaduan',
                      style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
              titleSpacing: 16,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 26),
                        onPressed: () => context.push(AppRouter.notifications),
                      ),
                      if (np.unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
                            child: Text(
                              np.unreadCount > 99
                                  ? '99+'
                                  : '${np.unreadCount}',
                              style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
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
                    if (!(auth.user?.isUserVerified ?? true)) ...[
                      const DashboardVerificationBanner(),
                      const SizedBox(height: 20),
                    ],
                    if (waiting > 0) ...[
                      DashboardWaitingAlert(count: waiting),
                      const SizedBox(height: 24),
                    ],
                    _SectionHeader(
                      title: 'Pengumuman Terbaru',
                      onTap: () => context.push(AppRouter.announcementsList),
                    ),
                    const SizedBox(height: 12),
                    const DashboardAnnouncementCarousel(),
                    const SizedBox(height: 28),
                    Text('Aksi Cepat',
                        style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    const DashboardQuickActionsGrid(),
                    const SizedBox(height: 28),
                    _SectionHeader(
                      title: 'Kategori Keluhan Populer',
                      onTap: () => context.push(AppRouter.popularCategories),
                    ),
                    const SizedBox(height: 12),
                    const DashboardCategoryChips(),
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _SectionHeader({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Lihat Semua',
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
        ),
      ],
    );
  }
}

