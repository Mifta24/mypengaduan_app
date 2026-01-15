import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;

  NotificationProvider(AuthService authService)
      : _notificationService = NotificationService(authService);

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  
  int _currentPage = 1;
  bool _hasMorePages = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMorePages => _hasMorePages;

  // Load notifications
  Future<void> loadNotifications({
    int page = 1,
    String? status,
    String? type,
    bool refresh = false,
  }) async {
    if (page == 1 || refresh) {
      _isLoading = true;
      _notifications = [];
    }
    
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _notificationService.getNotifications(
        page: page,
        status: status,
        type: type,
      );

      if (page == 1 || refresh) {
        _notifications = response.data;
      } else {
        _notifications.addAll(response.data);
      }

      _currentPage = page;
      _hasMorePages = response.meta.hasMorePages;
      
      // Count unread notifications
      _unreadCount = _notifications.where((n) => !n.isRead).length;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load next page
  Future<void> loadNextPage({
    String? status,
    String? type,
  }) async {
    if (_hasMorePages && !_isLoading) {
      await loadNotifications(
        page: _currentPage + 1,
        status: status,
        type: type,
      );
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final success = await _notificationService.markAsRead(notificationId);
      
      if (success) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _unreadCount = _notifications.where((n) => !n.isRead).length;
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  // Mark all as read
  Future<bool> markAllAsRead() async {
    try {
      final success = await _notificationService.markAllAsRead();
      
      if (success) {
        // Update local state
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        _unreadCount = 0;
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  // Register FCM token
  Future<bool> registerFCMToken(String token) async {
    try {
      return await _notificationService.registerFCMToken(token);
    } catch (e) {
      return false;
    }
  }

  // Add new notification (called when receiving push notification)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadCount++;
    }
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
