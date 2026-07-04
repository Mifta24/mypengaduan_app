import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';
import '../../services/announcement_service.dart';
import '../../theme/app_theme.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  bool _hasLoadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        final provider = context.read<NotificationProvider>();
        if (provider.notifications.isEmpty && !provider.isLoading) {
          _load();
        }
      });
    }
  }

  Future<void> _load() async {
    await context.read<NotificationProvider>().loadNotifications(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text('Notifikasi',
            style: GoogleFonts.nunito(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, provider, __) {
              if (provider.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await provider.markAllAsRead();
                  if (ok && mounted) {
                    messenger.showSnackBar(SnackBar(
                      content: Text('Semua notifikasi sudah dibaca',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w500)),
                      backgroundColor: AppTheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  }
                },
                child: Text('Baca Semua',
                    style: GoogleFonts.nunito(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (_, provider, __) {
          // Loading
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          // Error
          if (provider.errorMessage != null) {
            final isAuth = provider.errorMessage!.contains('Sesi') ||
                provider.errorMessage!.contains('Token');
            return _ErrorView(
              isAuth: isAuth,
              message: provider.errorMessage!,
              onRetry: isAuth ? () => _logout(context) : _load,
            );
          }

          // Empty
          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Tidak ada notifikasi',
                      style: GoogleFonts.nunito(
                          fontSize: 16, fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text('Notifikasi akan muncul di sini',
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          // List
          final notifs = provider.notifications;
          final unread = notifs.where((n) => !n.isRead).toList();
          final read   = notifs.where((n) => n.isRead).toList();

          return RefreshIndicator(
            onRefresh: _load,
            color: AppTheme.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                if (unread.isNotEmpty) ...[
                  _sectionLabel('Belum Dibaca', unread.length),
                  const SizedBox(height: 8),
                  ...unread.map((n) => _NotifCard(
                        key: ValueKey(n.id),
                        notif: n,
                        onTap: () async {
                          final ctx = context;
                          await provider.markAsRead(n.id);
                          if (ctx.mounted) _navigateFromNotif(ctx, n);
                        },
                        onDelete: () => _deleteNotification(context, n),
                      )),
                  const SizedBox(height: 16),
                ],
                if (read.isNotEmpty) ...[
                  _sectionLabel('Sudah Dibaca', null),
                  const SizedBox(height: 8),
                  ...read.map((n) => _NotifCard(
                        key: ValueKey(n.id),
                        notif: n,
                        onTap: () => _navigateFromNotif(context, n),
                        onDelete: () => _deleteNotification(context, n),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String label, int? count) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary)),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary, borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count',
                style: GoogleFonts.nunito(
                    fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ],
    );
  }

  Future<void> _navigateFromNotif(BuildContext ctx, NotificationModel notif) async {
    final type = notif.type.toLowerCase();
    final data = notif.data ?? {};

    // ── Complaint / status update ────────────────────────────
    if (type == 'complaint' || type == 'complaint_update') {
      final rawId = data['complaint_id'] ?? data['id'];
      final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
      if (id != null && ctx.mounted) {
        ctx.push('/complaint/$id');
      }
      return;
    }

    // ── Announcement ─────────────────────────────────────────
    if (type == 'announcement') {
      final rawId = data['announcement_id'] ?? data['id'];
      final idOrSlug = rawId?.toString() ?? '';

      if (idOrSlug.isNotEmpty) {
        // Tampilkan loading sementara fetch
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text('Membuka pengumuman...',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w500)),
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
        try {
          final announcement =
              await AnnouncementService().getAnnouncementDetail(idOrSlug);
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
            ctx.push(AppRouter.announcementDetail, extra: announcement);
          }
        } catch (_) {
          // Fallback ke list
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
            ctx.push(AppRouter.announcementsList);
          }
        }
      } else {
        if (ctx.mounted) {
          ctx.push(AppRouter.announcementsList);
        }
      }
    }
  }

  Future<void> _deleteNotification(BuildContext context, NotificationModel notif) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Notifikasi?', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        content: Text('Notifikasi ini akan dihapus secara permanen.', style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.nunito()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<NotificationProvider>();
    final success = await provider.deleteNotification(notif.id);

    if (!success && context.mounted) {
      messenger.showSnackBar(SnackBar(
        content: Text('Gagal menghapus notifikasi', style: GoogleFonts.nunito(fontWeight: FontWeight.w500)),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _logout(BuildContext ctx) async {
    try { ctx.read<ComplaintProvider>().clear(); } catch (_) {}
    try { ctx.read<NotificationProvider>().clear(); } catch (_) {}
    try { ctx.read<AnnouncementProvider>().clear(); } catch (_) {}
    await ctx.read<AuthProvider>().logout();
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  const _NotifCard({super.key, required this.notif, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final unread = !notif.isRead;
    final iconColor = _iconColor(notif.type);
    final iconBg   = iconColor.withValues(alpha: 0.12);

    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete?.call();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: unread ? AppTheme.primary.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unread ? AppTheme.primary.withValues(alpha: 0.25) : AppTheme.border,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Unread indicator strip
              if (unread)
                Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_iconData(notif.type), size: 20, color: iconColor),
                      ),
                      const SizedBox(width: 12),
                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(notif.title,
                                      style: GoogleFonts.nunito(
                                          fontSize: 14,
                                          fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                                          color: AppTheme.textPrimary)),
                                ),
                                if (unread)
                                  Container(
                                    width: 8, height: 8,
                                    margin: const EdgeInsets.only(left: 6, top: 3),
                                    decoration: const BoxDecoration(
                                        color: AppTheme.primary, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(notif.body,
                                style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    height: 1.4),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded,
                                    size: 12, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text(_timeAgo(notif.createdAt),
                                    style: GoogleFonts.nunito(
                                        fontSize: 11, color: Colors.grey.shade400)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  IconData _iconData(String type) {
    switch (type.toLowerCase()) {
      case 'complaint':
      case 'complaint_update': return Icons.report_rounded;
      case 'announcement':     return Icons.campaign_rounded;
      case 'system':           return Icons.info_rounded;
      default:                 return Icons.notifications_rounded;
    }
  }

  Color _iconColor(String type) {
    switch (type.toLowerCase()) {
      case 'complaint':
      case 'complaint_update': return const Color(0xFFEF4444);
      case 'announcement':     return AppTheme.primary;
      case 'system':           return const Color(0xFF0891B2);
      default:                 return AppTheme.textSecondary;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24)   return '${diff.inHours} jam lalu';
    if (diff.inDays < 7)     return '${diff.inDays} hari lalu';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final bool isAuth;
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.isAuth, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAuth ? Icons.lock_outline_rounded : Icons.error_outline_rounded,
              size: 64,
              color: isAuth ? const Color(0xFFD97706) : Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isAuth ? 'Sesi Berakhir' : 'Gagal Memuat',
              style: GoogleFonts.nunito(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(message,
                style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(isAuth ? Icons.logout_rounded : Icons.refresh_rounded, size: 18),
              label: Text(isAuth ? 'Login Ulang' : 'Coba Lagi',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAuth ? const Color(0xFFD97706) : AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
