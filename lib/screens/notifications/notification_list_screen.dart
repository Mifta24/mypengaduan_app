import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  @override
  void initState() {
    super.initState();
    // Don't load immediately - load only after screen is visible
    print('📱 [NotificationScreen] Screen initialized - will load after frame');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load only once when screen becomes visible
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          // Check if data already loaded by dashboard
          final provider = context.read<NotificationProvider>();
          if (provider.notifications.isEmpty && !provider.isLoading) {
            print('📱 [NotificationScreen] No data yet - loading notifications now');
            _loadNotifications();
          } else {
            print('📱 [NotificationScreen] Data already loaded (${provider.notifications.length} items) - skipping load');
          }
        }
      });
    }
  }

  bool _hasLoadedOnce = false;

  Future<void> _loadNotifications() async {
    // Debug: Show current user info
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        print('🧑 [NotificationScreen] Current logged in user:');
        print('   ID: ${authProvider.user!.id}');
        print('   Name: ${authProvider.user!.name}');
        print('   Email: ${authProvider.user!.email}');
        print('   Role: ${authProvider.user!.role}');
        print('📊 Database has notifications for user_id = 2');
        print('⚠️ If user ID ≠ 2, that\'s why notifications are empty!');
      }
    } catch (e) {
      print('Could not get auth provider: $e');
    }
    
    final provider = context.read<NotificationProvider>();
    await provider.loadNotifications(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () async {
                    final success = await provider.markAllAsRead();
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Semua notifikasi ditandai sudah dibaca'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Tandai Semua'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            );
          }

          // Show error message if exists
          if (provider.errorMessage != null) {
            // Check if it's authentication error
            final isAuthError = provider.errorMessage!.contains('Sesi Anda telah berakhir') ||
                                provider.errorMessage!.contains('Token expired');
            
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAuthError ? Icons.lock_outline : Icons.error_outline,
                    size: 80,
                    color: isAuthError ? Colors.orange[300] : Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAuthError ? 'Sesi Berakhir' : 'Gagal memuat notifikasi',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.errorMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isAuthError)
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Clear all provider states before logout
                        try {
                          context.read<ComplaintProvider>().clear();
                        } catch (e) {
                          print('ComplaintProvider not available: $e');
                        }
                        try {
                          context.read<NotificationProvider>().clear();
                        } catch (e) {
                          print('NotificationProvider not available: $e');
                        }
                        try {
                          context.read<AnnouncementProvider>().clear();
                        } catch (e) {
                          print('AnnouncementProvider not available: $e');
                        }
                        
                        // Logout and redirect to login
                        final authProvider = context.read<AuthProvider>();
                        await authProvider.logout();
                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login',
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Login Ulang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _loadNotifications,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada notifikasi',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifikasi akan muncul di sini',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadNotifications,
            color: AppTheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _buildNotificationCard(notification, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? Colors.white 
          : AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: notification.isRead 
            ? null 
          : Border.all(color: AppTheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (!notification.isRead) {
              await provider.markAsRead(notification.id);
            }
            // TODO: Navigate based on notification type
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getIconBackgroundColor(notification.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getIconColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: notification.isRead 
                                    ? FontWeight.w500 
                                    : FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(notification.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
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
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'complaint':
      case 'complaint_update':
        return Icons.report_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'system':
        return Icons.info_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'complaint':
      case 'complaint_update':
        return const Color(0xFFEF4444);
      case 'announcement':
        return const Color(0xFF6366F1);
      case 'system':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getIconBackgroundColor(String type) {
    switch (type.toLowerCase()) {
      case 'complaint':
      case 'complaint_update':
        return const Color(0xFFFEE2E2);
      case 'announcement':
        return const Color(0xFFEEF2FF);
      case 'system':
        return const Color(0xFFD1FAE5);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }
}
