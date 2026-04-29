import 'dart:async';
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
import '../notifications/notification_list_screen.dart';
import '../announcements/announcement_list_screen.dart';
import '../profile/profile_screen.dart';

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
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation to login screen
        return false;
      },
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_rounded),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.report_outlined),
                selectedIcon: Icon(Icons.report),
                label: 'Keluhan',
              ),
              NavigationDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: 'Pengumuman',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final PageController _announcementPageController = PageController();
  Timer? _announcementTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();

    _announcementTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_announcementPageController.hasClients) {
        final provider = Provider.of<AnnouncementProvider>(context, listen: false);
        final itemCount = provider.announcements.take(3).length;
        if (itemCount > 1) {
          int nextPage = _announcementPageController.page!.round() + 1;
          if (nextPage >= itemCount) nextPage = 0;
          _announcementPageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    print('🏠 [DashboardScreen] Screen initialized - will load after visible');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load only once when screen becomes visible
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          print('🏠 [DashboardScreen] Screen visible - loading data now');
          _loadData();
        }
      });
    }
  }

  bool _hasLoadedOnce = false;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi,';
    if (hour < 15) return 'Selamat Siang,';
    if (hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 15) return Icons.wb_sunny_rounded;
    if (hour < 18) return Icons.wb_twilight_rounded;
    return Icons.nights_stay_rounded;
  }

  @override
  void dispose() {
    _announcementTimer?.cancel();
    _announcementPageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final complaintProvider =
        Provider.of<ComplaintProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    final announcementProvider =
        Provider.of<AnnouncementProvider>(context, listen: false);

    // Load statistics
    await complaintProvider.loadStatistics();

    // Load notifications for unread badge
    await notificationProvider.loadNotifications(refresh: true);

    // Load recent announcements (user public endpoint)
    await announcementProvider.loadPublicAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final waitingConfirmationCount =
        _getWaitingConfirmationCount(complaintProvider.statistics);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Modern App Bar
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://bleuglaciotrip.co.in/wp-content/uploads/2025/05/INDONESIA.jpg',
                      ),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black45,
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getGreetingIcon(),
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getGreeting(),
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      authProvider.user?.name ?? 'User',
                                      style: GoogleFonts.nunito(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                // Notification Icon
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationListScreen(),
                            ),
                          );
                        },
                      ),
                      // Badge for unread notifications
                      if (notificationProvider.unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                notificationProvider.unreadCount > 99
                                    ? '99+'
                                    : '${notificationProvider.unreadCount}',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (waitingConfirmationCount > 0) ...[
                      _buildWaitingConfirmationAlert(
                        context,
                        waitingConfirmationCount,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Complaint Steps Section
                    _buildSectionTitle('Alur Pengaduan'),
                    const SizedBox(height: 16),
                    _buildComplaintSteps(),
                    const SizedBox(height: 32),

                    // Quick Actions Section
                    _buildSectionTitle('Aksi Cepat'),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                    const SizedBox(height: 32),

                    // Recent Announcements Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('Pengumuman Terbaru'),
                        TextButton(
                          onPressed: () =>
                              context.push(AppRouter.announcementsList),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Lihat Semua',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRecentAnnouncements(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  int _getWaitingConfirmationCount(Map<String, dynamic>? stats) {
    if (stats == null) return 0;

    int readValue(List<String> keys) {
      for (final key in keys) {
        final value = stats[key];
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    return readValue([
      'waiting_user_confirmation',
      'waiting_user_confirmations',
      'waiting_confirmation',
      'waitingUserConfirmation',
    ]);
  }

  Widget _buildWaitingConfirmationAlert(BuildContext context, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDBA74), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEA580C).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: Color(0xFFEA580C),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Konfirmasi Penyelesaian Dibutuhkan',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ada $count pengaduan yang sudah ditangani admin dan menunggu konfirmasi Anda.',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: const Color(0xFF9A3412),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => context.push(AppRouter.myComplaints),
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: Text(
                    'Lihat Pengaduan',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),
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

  Widget _buildComplaintSteps() {
    final steps = [
      {'icon': Icons.edit_document, 'label': 'Tulis Laporan'},
      {'icon': Icons.published_with_changes, 'label': 'Proses Verifikasi'},
      {'icon': Icons.support_agent, 'label': 'Tindak Lanjut'},
      {'icon': Icons.task_alt, 'label': 'Selesai'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: AppTheme.border,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
            );
          }
          final stepIndex = index ~/ 2;
          final step = steps[stepIndex];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step['icon'] as IconData,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 65,
                child: Text(
                  step['label'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'icon': Icons.add_circle_rounded,
        'title': 'Buat\nPengaduan',
        'color': AppTheme.primary,
        'onTap': () {
          // Check KTP verification before navigating
          final user = Provider.of<AuthProvider>(context, listen: false).user;
          if (user != null && !user.isUserVerified) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFEA580C)),
                    const SizedBox(width: 8),
                    Text(
                      'Akun Belum Terverifikasi',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
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
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                    ),
                    child: Text('Mengerti',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
            return;
          }
          context.push(AppRouter.createComplaint);
        },
      },
      {
        'icon': Icons.history_rounded,
        'title': 'Riwayat\nKeluhan',
        'color': const Color(0xFF0891B2),
        'onTap': () {
          // Navigate to complaints list with go route
          context.push(AppRouter.myComplaints);
        },
      },
      {
        'icon': Icons.campaign_rounded,
        'title': 'Pengumuman\nSistem',
        'color': const Color(0xFF15803D),
        'onTap': () {
          context.push(AppRouter.announcementsList);
        },
      },
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: actions.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < actions.length - 1 ? 12.0 : 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (action['color'] as Color).withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: action['onTap'] as VoidCallback,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Icon(
                          action['icon'] as IconData,
                          color: action['color'] as Color,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  action['title'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentAnnouncements() {
    return Consumer<AnnouncementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.homeAnnouncements.isEmpty) {
          return Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.homeAnnouncements.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Center(
              child: Text(
                'Belum ada pengumuman terbaru',
                style: GoogleFonts.nunito(color: AppTheme.textSecondary),
              ),
            ),
          );
        }

        final items = provider.homeAnnouncements.take(3).toList();

        return Column(
          children: [
            // PageView Carousel
            SizedBox(
              height: 110,
              child: PageView.builder(
                controller: _announcementPageController,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final announcement = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () => context.push(AppRouter.announcementsList),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primary.withOpacity(0.07),
                              AppTheme.primary.withOpacity(0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.2),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.campaign_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    announcement['title'] ?? 'Pengumuman',
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    announcement['summary'] ??
                                        announcement['content'] ??
                                        '',
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Dot Indicator
            if (items.length > 1) ...[
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _announcementPageController,
                builder: (context, child) {
                  int currentPage = 0;
                  if (_announcementPageController.hasClients &&
                      _announcementPageController.page != null) {
                    currentPage = _announcementPageController.page!.round();
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(items.length, (index) {
                      final isActive = index == currentPage % items.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.primary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
