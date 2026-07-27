import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/complaint_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/announcement_provider.dart';
import '../../../routes/app_router.dart';
import '../home/home_tab.dart';
import '../complaints/complaints_tab.dart';
import '../announcements/announcements_tab.dart';
import '../users/users_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  late List<bool> _initializedTabs;

  // 4 tab: Beranda, Pengaduan, Pengumuman, Pengguna
  final List<Widget> _pages = [
    const AdminHomeTab(),
    const AdminComplaintsTab(),
    const AdminAnnouncementsTab(),
    const AdminUsersTab(),
  ];

  @override
  void initState() {
    super.initState();
    _initializedTabs = List.generate(_pages.length, (i) => i == 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if (auth.isAuthenticated) {
          Provider.of<NotificationProvider>(context, listen: false)
              .loadNotifications(refresh: true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final notif = Provider.of<NotificationProvider>(context);
    final user = auth.user;

    return AdminTabNavigator(
      switchTab: (i) {
        setState(() {
          _selectedIndex = i;
          _initializedTabs[i] = true;
        });
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        // ── AppBar dark green ──────────────────────────────────
        appBar: AppBar(
          backgroundColor: AppTheme.bgDark,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 16,
          title: Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text('MyPengaduan Admin',
                  style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ],
          ),
          actions: [
            // Notification bell + badge
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 26),
                  onPressed: () => context.push(AppRouter.notifications),
                ),
                if (notif.unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        notif.unreadCount > 99 ? '99+' : '${notif.unreadCount}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            // Admin avatar dropdown
            PopupMenuButton<String>(
              onSelected: (v) => _handleMenu(v, context, auth),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(children: [
                    Icon(Icons.manage_accounts, size: 18),
                    SizedBox(width: 8),
                    Text('Profil Admin')
                  ]),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red))
                  ]),
                ),
              ],
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : 'A',
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // ── Body ──────────────────────────────────────────────
        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(_pages.length,
              (i) => _initializedTabs[i] ? _pages[i] : const SizedBox.shrink()),
        ),
        // ── FAB (tab Pengumuman) ──────────────────────────────
        floatingActionButton: _selectedIndex == 2
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final result =
                      await context.push<bool>(AppRouter.adminAnnouncementsAdd);
                  if (result == true && context.mounted) {
                    final tab = _pages[2] as AdminAnnouncementsTab;
                    tab.reload();
                  }
                },
                icon: const Icon(Icons.add),
                label: Text('Tambah',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              )
            : null,
        // ── Bottom Navigation 4 item ──────────────────────────
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2))
            ],
          ),
          child: NavigationBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            height: 64,
            indicatorColor: AppTheme.primary.withValues(alpha: 0.12),
            selectedIndex: _selectedIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) {
              setState(() {
                _selectedIndex = i;
                _initializedTabs[i] = true;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined, size: 22),
                selectedIcon: Icon(Icons.dashboard_rounded,
                    size: 24, color: AppTheme.primary),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: const Icon(Icons.report_outlined, size: 22),
                selectedIcon: Icon(Icons.report_rounded,
                    size: 24, color: AppTheme.primary),
                label: 'Pengaduan',
              ),
              NavigationDestination(
                icon: const Icon(Icons.campaign_outlined, size: 22),
                selectedIcon: Icon(Icons.campaign_rounded,
                    size: 24, color: AppTheme.primary),
                label: 'Pengumuman',
              ),
              NavigationDestination(
                icon: const Icon(Icons.people_outline, size: 22),
                selectedIcon: Icon(Icons.people_rounded,
                    size: 24, color: AppTheme.primary),
                label: 'Pengguna',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleMenu(
      String value, BuildContext ctx, AuthProvider auth) async {
    if (value == 'profile') {
      ctx.push(AppRouter.adminProfile);
    } else if (value == 'logout') {
      final confirm = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Konfirmasi Logout',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          content: Text('Apakah Anda yakin ingin keluar?',
              style: GoogleFonts.nunito()),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        ),
      );
      if (confirm == true && ctx.mounted) {
        try {
          ctx.read<ComplaintProvider>().clear();
        } catch (_) {}
        try {
          ctx.read<NotificationProvider>().clear();
        } catch (_) {}
        try {
          ctx.read<AnnouncementProvider>().clear();
        } catch (_) {}
        await auth.logout();
        if (ctx.mounted) ctx.go(AppRouter.landing);
      }
    }
  }
}

// Helper untuk navigasi ke tab dari luar (dipanggil oleh quick actions)
class AdminTabNavigator extends InheritedWidget {
  final void Function(int) switchTab;
  const AdminTabNavigator(
      {super.key, required this.switchTab, required super.child});
  static AdminTabNavigator? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdminTabNavigator>();
  @override
  bool updateShouldNotify(AdminTabNavigator old) => false;
}
