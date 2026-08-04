import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../complaints/complaint_list_screen.dart';
import '../announcements/announcement_list_screen.dart';
import '../profile/profile_screen.dart';
import 'dashboard_screen.dart';

void showUnverifiedDialog(BuildContext context) {
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
          child: Text('Mengerti',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

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
              showUnverifiedDialog(context);
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
            _NavItem(
                icon: Icons.home_rounded,
                outlinedIcon: Icons.home_outlined,
                label: 'Beranda',
                index: 0,
                current: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i)),
            _NavItem(
                icon: Icons.history_rounded,
                outlinedIcon: Icons.history_outlined,
                label: 'Riwayat',
                index: 1,
                current: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i)),
            const Expanded(child: SizedBox()),
            _NavItem(
                icon: Icons.campaign_rounded,
                outlinedIcon: Icons.campaign_outlined,
                label: 'Pengumuman',
                index: 2,
                current: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i)),
            _NavItem(
                icon: Icons.person_rounded,
                outlinedIcon: Icons.person_outline_rounded,
                label: 'Akun',
                index: 3,
                current: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i)),
          ],
        ),
      ),
    );
  }
}

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
                color: selected ? AppTheme.primary : Colors.grey.shade400,
                size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
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
