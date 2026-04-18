import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/notification_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final complaintProvider =
        Provider.of<ComplaintProvider>(context, listen: false);

    // Only load statistics, DON'T load notifications (too heavy)
    await complaintProvider.loadStatistics();
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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryDark,
                        AppTheme.primary,
                        AppTheme.secondary,
                      ],
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
                                child: const Icon(
                                  Icons.wb_sunny_outlined,
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
                                      'Selamat Datang!',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      authProvider.user?.name ?? 'User',
                                      style: GoogleFonts.poppins(
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
                                style: GoogleFonts.inter(
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

                    // Statistics Section
                    if (complaintProvider.statistics != null) ...[
                      _buildSectionTitle('Statistik Sistem'),
                      const SizedBox(height: 16),
                      _buildStatisticsGrid(complaintProvider.statistics!),
                      const SizedBox(height: 32),
                    ],

                    // Quick Actions Section
                    _buildSectionTitle('Aksi Cepat'),
                    const SizedBox(height: 16),
                    _buildQuickActions(context),
                    const SizedBox(height: 32),

                    // Features Section
                    _buildSectionTitle('Fitur Unggulan'),
                    const SizedBox(height: 16),
                    _buildFeatures(),
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
      style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ada $count pengaduan yang sudah ditangani admin dan menunggu konfirmasi Anda.',
                  style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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

  Widget _buildStatisticsGrid(Map<String, dynamic> stats) {
    int _getStatValue(List<String> keys, {int fallback = 0}) {
      for (final key in keys) {
        final value = stats[key];
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return fallback;
    }

    final totalComplaints =
        _getStatValue(['total_complaints', 'total', 'totalComplaints']);
    final resolvedComplaints =
        _getStatValue(['resolved', 'resolved_complaints', 'completed']);
    final pendingComplaints =
        _getStatValue(['pending', 'pending_complaints', 'in_progress']);
    final activeUsers =
        _getStatValue(['active_users', 'active', 'activeUsers', 'total_users']);

    final statItems = [
      {
        'title': 'Total Keluhan',
        'value': totalComplaints.toString(),
        'icon': Icons.description_rounded,
        'color': const Color(0xFF16A34A),
        'gradient': [const Color(0xFF22C55E), const Color(0xFF16A34A)],
      },
      {
        'title': 'Keluhan Selesai',
        'value': resolvedComplaints.toString(),
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF15803D),
        'gradient': [const Color(0xFF16A34A), const Color(0xFF15803D)],
      },
      {
        'title': 'Keluhan Pending',
        'value': pendingComplaints.toString(),
        'icon': Icons.pending_rounded,
        'color': const Color(0xFFD97706),
        'gradient': [const Color(0xFFFBBF24), const Color(0xFFD97706)],
      },
      {
        'title': 'Pengguna Aktif',
        'value': activeUsers.toString(),
        'icon': Icons.people_rounded,
        'color': const Color(0xFF0891B2),
        'gradient': [const Color(0xFF22D3EE), const Color(0xFF0891B2)],
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5, // Increased from 1.4 to 1.5 to fix overflow
      ),
      itemCount: statItems.length,
      itemBuilder: (context, index) {
        final item = statItems[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: item['gradient'] as List<Color>,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (item['color'] as Color).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12), // Reduced from 16 to 12
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.all(6), // Reduced from 8 to 6
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: Colors.white,
                            size: 18, // Reduced from 20 to 18
                          ),
                        ),
                        Expanded(
                          // Changed from Flexible to Expanded
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item['value'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 20, // Reduced from 22 to 20
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height:
                                      1.0, // Tighter line height from 1.1 to 1.0
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                item['title'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 9, // Reduced from 10 to 9
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'icon': Icons.add_circle_rounded,
        'title': 'Buat Pengaduan',
        'subtitle': 'Sampaikan keluhan Anda',
        'color': AppTheme.primary,
        'onTap': () {
          // Navigate to create complaint screen
          context.push(AppRouter.createComplaint);
        },
      },
      {
        'icon': Icons.history_rounded,
        'title': 'Riwayat Keluhan',
        'subtitle': 'Lihat keluhan Anda',
        'color': const Color(0xFF0891B2),
        'onTap': () {
          // Navigate to complaints list with go route
          context.push(AppRouter.myComplaints);
        },
      },
      {
        'icon': Icons.campaign_rounded,
        'title': 'Pengumuman',
        'subtitle': 'Info terkini dari pengurus',
        'color': const Color(0xFF15803D),
        'onTap': () {
          context.push(AppRouter.announcementsList);
        },
      },
    ];

    return Column(
      children: actions.map((action) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action['title'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            action['subtitle'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeatures() {
    final features = [
      {
        'icon': Icons.track_changes,
        'title': 'Tracking Real-time',
        'description': 'Pantau status keluhan Anda secara real-time',
      },
      {
        'icon': Icons.bolt,
        'title': 'Respon Cepat',
        'description': 'Tim pengurus siap merespon keluhan dengan cepat',
      },
      {
        'icon': Icons.chat_bubble_outline_rounded,
        'title': 'Komunikasi Transparan',
        'description': 'Komunikasi dua arah yang transparan',
      },
      {
        'icon': Icons.smartphone_rounded,
        'title': 'Mobile Friendly',
        'description': 'Akses sistem dari smartphone kapan saja',
      },
    ];

    return Column(
      children: features.map((feature) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['description'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
