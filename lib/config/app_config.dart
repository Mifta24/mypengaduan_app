class AppConfig {
  // API Configuration
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://mypengaduan.miftahaldi.my.id/api/',
  );
  
  // App Configuration
  static const String appName = 'MyPengaduan';
  static const String appVersion = '1.0.0';
  
  // Pagination
  static const int defaultPerPage = 15;
  
  // Timeout
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String fcmTokenKey = 'fcm_token';
  
  // Notification Types
  static const String notificationComplaintCreated = 'complaint_created';
  static const String notificationStatusChanged = 'complaint_status_changed';
  static const String notificationAdminResponse = 'admin_response';
  static const String notificationComplaintResolved = 'complaint_resolved';
  static const String notificationAnnouncementCreated = 'announcement_created';
  static const String notificationCommentAdded = 'comment_added';
}
