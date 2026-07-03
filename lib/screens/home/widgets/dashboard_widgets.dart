import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/announcement_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_router.dart';
import '../../../theme/app_theme.dart';
import '../home_screen.dart' show showUnverifiedDialog;

class DashboardVerificationBanner extends StatelessWidget {
  const DashboardVerificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pending_actions_rounded,
                color: Color(0xFFD97706), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Akun Belum Terverifikasi',
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E))),
                const SizedBox(height: 4),
                Text(
                  'KTP Anda sedang menunggu verifikasi admin. Fitur pengaduan akan aktif setelah diverifikasi.',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF92400E),
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardWaitingAlert extends StatelessWidget {
  final int count;
  const DashboardWaitingAlert({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)]),
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
            child: const Icon(Icons.fact_check_rounded,
                color: Color(0xFFEA580C), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Konfirmasi Penyelesaian Dibutuhkan',
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF9A3412))),
                const SizedBox(height: 4),
                Text(
                  'Ada $count pengaduan yang sudah ditangani dan menunggu konfirmasi Anda.',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF9A3412),
                      height: 1.4),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => context.push(AppRouter.myComplaints),
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: Text('Lihat Pengaduan',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
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
}

class DashboardAnnouncementCarousel extends StatelessWidget {
  const DashboardAnnouncementCarousel({super.key});

  String _monthName(int month) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return names[month];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnnouncementProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.homeAnnouncements.isEmpty) {
          return SizedBox(
            height: 145,
            child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary)),
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
                  : (item.attachments?.isNotEmpty == true
                      ? item.attachments!.first
                      : null);
              final date = item.publishedAt != null
                  ? '${item.publishedAt!.day} ${_monthName(item.publishedAt!.month)} ${item.publishedAt!.year}'
                  : '';

              return GestureDetector(
                onTap: () => context.push(
                  AppRouter.announcementDetail,
                  extra: item,
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
                      if (imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(imageUrl,
                              width: 180,
                              height: 145,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox()),
                        ),
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
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (date.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(date,
                                  style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      color: Colors.white
                                          .withValues(alpha: 0.75))),
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
}

class DashboardQuickActionsGrid extends StatelessWidget {
  const DashboardQuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.add_circle_rounded,
        label: 'Lapor\nKeluhan',
        color: AppTheme.primary,
        onTap: () {
          final user =
              Provider.of<AuthProvider>(context, listen: false).user;
          if (user != null && !user.isUserVerified) {
            showUnverifiedDialog(context);
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
      children: actions.map(_buildItem).toList(),
    );
  }

  Widget _buildItem(_QuickAction a) {
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
}

class DashboardCategoryChips extends StatelessWidget {
  const DashboardCategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    const categories = [
      (Icons.construction_rounded,      'Jalan &\nInfrastruktur', AppTheme.primary),
      (Icons.cleaning_services_rounded, 'Kebersihan',             AppTheme.secondary),
      (Icons.assignment_rounded,        'Perizinan',              AppTheme.primaryDark),
      (Icons.category_rounded,          'Lainnya',                AppTheme.accent),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          return GestureDetector(
            onTap: () => context.push(AppRouter.popularCategories),
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: BoxDecoration(
                color: cat.$3.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: cat.$3.withValues(alpha: 0.25), width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cat.$3.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cat.$1, color: cat.$3, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.$2,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cat.$3,
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
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
}
