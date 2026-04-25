import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/complaint_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/announcement_provider.dart';
import '../../../routes/app_router.dart';
import '../../home/landing_screen.dart';
import '../../test/fcm_debug_screen.dart';
import '../home/home_tab.dart';
import '../complaints/complaints_tab.dart';
import '../users/users_tab.dart';
import '../announcements/announcements_tab.dart';
import '../announcements/add_announcement_screen.dart';
import '../categories/categories_tab.dart';
import '../categories/add_category_screen.dart';
import '../reports/reports_tab.dart';
import '../profile/admin_profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  late List<bool> _initializedTabs;

  final List<Widget> _pages = [
    const AdminHomeTab(),
    const AdminComplaintsTab(),
    const AdminUsersTab(),
    const AdminAnnouncementsTab(),
    const AdminCategoriesTab(),
    const AdminReportsTab(),
  ];

  @override
  void initState() {
    super.initState();
    _initializedTabs = List.generate(_pages.length, (index) => index == 0);
    // Load notifications when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated) {
          final notificationProvider =
              Provider.of<NotificationProvider>(context, listen: false);
          notificationProvider.loadNotifications(refresh: true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.05),
        elevation: 1,
        actions: [
          // Notification button with badge
          Stack(
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.black87,
                ),
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {
                  context.push(AppRouter.notifications);
                },
              ),
              if (notificationProvider.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        notificationProvider.unreadCount > 99
                            ? '99+'
                            : notificationProvider.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminProfileScreen(),
                  ),
                );
              } else if (value == 'fcm_debug') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FCMDebugScreen(),
                  ),
                );
              } else if (value == 'logout') {
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

                if (result == true && context.mounted) {
                  // Clear all provider states before logout
                  try {
                    context.read<ComplaintProvider>().clear();
                  } catch (e) {
                    debugPrint('ComplaintProvider not available: $e');
                  }
                  try {
                    context.read<NotificationProvider>().clear();
                  } catch (e) {
                    debugPrint('NotificationProvider not available: $e');
                  }
                  try {
                    context.read<AnnouncementProvider>().clear();
                  } catch (e) {
                    debugPrint('AnnouncementProvider not available: $e');
                  }

                  await authProvider.logout();
                  if (context.mounted) {
                    context.go(AppRouter.landing);
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'fcm_debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report, size: 20, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('FCM Debug'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.14),
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user?.name ?? 'Admin',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.surface,
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(_pages.length, (index) {
          return _initializedTabs[index]
              ? _pages[index]
              : const SizedBox.shrink();
        }),
      ),
      floatingActionButton: _selectedIndex == 3
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddAnnouncementScreen(),
                  ),
                );
                if (result == true && context.mounted) {
                  // Reload announcements
                  final announcementsTab = _pages[3] as AdminAnnouncementsTab;
                  announcementsTab.reload();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Buat Pengumuman'),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : _selectedIndex == 4
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddCategoryScreen(),
                      ),
                    );
                    if (result == true && context.mounted) {
                      // Reload categories
                      final categoriesTab = _pages[4] as AdminCategoriesTab;
                      categoriesTab.reload();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Kategori'),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                )
              : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 65,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
          selectedIndex: _selectedIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
              _initializedTabs[index] = true;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, size: 22),
              selectedIcon: Icon(Icons.dashboard, size: 24, color: AppTheme.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.report_problem_outlined, size: 22),
              selectedIcon: Icon(Icons.report_problem, size: 24, color: AppTheme.primary),
              label: 'Aduan',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline, size: 22),
              selectedIcon: Icon(Icons.people, size: 24, color: AppTheme.primary),
              label: 'User',
            ),
            NavigationDestination(
              icon: Icon(Icons.announcement_outlined, size: 22),
              selectedIcon: Icon(Icons.announcement, size: 24, color: AppTheme.primary),
              label: 'Info',
            ),
            NavigationDestination(
              icon: Icon(Icons.category_outlined, size: 22),
              selectedIcon: Icon(Icons.category, size: 24, color: AppTheme.primary),
              label: 'Kategori',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment_outlined, size: 22),
              selectedIcon: Icon(Icons.assessment, size: 24, color: AppTheme.primary),
              label: 'Laporan',
            ),
          ],
        ),
      ),
    );
  }
}
