import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  late NotificationService _notificationService;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMorePages = false;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(AuthService());
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _notifications = [];
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _notificationService.getNotifications(
        page: _currentPage,
      );

      setState(() {
        if (refresh) {
          _notifications = response.data;
        } else {
          _notifications.addAll(response.data);
        }
        _hasMorePages = response.meta.hasMorePages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(int notificationId, int index) async {
    final success = await _notificationService.markAsRead(notificationId);
    if (success) {
      setState(() {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          body: _notifications[index].body,
          data: _notifications[index].data,
          isRead: true,
          createdAt: _notifications[index].createdAt,
          updatedAt: DateTime.now(),
        );
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await _notificationService.markAllAsRead();
    if (success) {
      await _loadNotifications(refresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua notifikasi ditandai sudah dibaca')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
            tooltip: 'Tandai semua sudah dibaca',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNotifications(refresh: true),
        child: _isLoading && _notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada notifikasi',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _notifications.length + (_hasMorePages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _notifications.length) {
                        return _isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : TextButton(
                                onPressed: () {
                                  _currentPage++;
                                  _loadNotifications();
                                },
                                child: const Text('Load More'),
                              );
                      }

                      final notification = _notifications[index];
                      return _buildNotificationItem(notification, index);
                    },
                  ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, int index) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: notification.isRead ? 0 : 2,
      color: notification.isRead ? null : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.type),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : IconButton(
                icon: const Icon(Icons.mark_email_read),
                onPressed: () => _markAsRead(notification.id, index),
                tooltip: 'Tandai sudah dibaca',
              ),
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification.id, index);
          }
          // TODO: Navigate based on notification type
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'complaint_created':
        return Icons.report;
      case 'complaint_status_changed':
        return Icons.update;
      case 'admin_response':
        return Icons.comment;
      case 'complaint_resolved':
        return Icons.check_circle;
      case 'announcement_created':
        return Icons.campaign;
      case 'comment_added':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'complaint_created':
        return Colors.blue;
      case 'complaint_status_changed':
        return Colors.orange;
      case 'admin_response':
        return Colors.purple;
      case 'complaint_resolved':
        return Colors.green;
      case 'announcement_created':
        return Colors.red;
      case 'comment_added':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
