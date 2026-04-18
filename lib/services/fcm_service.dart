import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'notification_service.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationService _notificationService;

  FCMService(this._notificationService);

  // Initialize FCM
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    }

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint('✅ FCM Token berhasil didapat: $token');
      await _saveFCMToken(token);
      
      // Register token to backend with error handling
      try {
        final success = await _notificationService.registerFCMToken(token);
        if (success) {
          debugPrint('✅ FCM Token berhasil didaftarkan ke backend');
        } else {
          debugPrint('⚠️ FCM Token gagal didaftarkan ke backend');
        }
      } catch (e) {
        debugPrint('❌ Error registering FCM token: $e');
      }
    } else {
      debugPrint('❌ Failed to get FCM token');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM Token refreshed: $newToken');
      await _saveFCMToken(newToken);
      await _notificationService.registerFCMToken(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification when app is opened from terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 Foreground message received: ${message.messageId}');
    debugPrint('📨 Title: ${message.notification?.title}');
    debugPrint('📨 Body: ${message.notification?.body}');
    debugPrint('📨 Data: ${message.data}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      debugPrint('📲 Showing local notification...');
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data.toString(),
      );
    } else {
      debugPrint('⚠️ Notification is null or no Android data');
    }
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    
    // Navigate based on notification type
    final type = message.data['type'] as String?;
    final data = message.data;
    
    // Delay to ensure app is fully loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        switch (type) {
          case 'complaint_created':
          case 'complaint_updated':
          case 'complaint_status_changed':
            final complaintId = data['complaint_id'];
            if (complaintId != null) {
              // Navigate to complaint detail
              // Using go_router: context.go('/complaint/$complaintId')
              debugPrint('Navigate to complaint: $complaintId');
            }
            break;
          
          case 'comment_added':
            final complaintId = data['complaint_id'];
            if (complaintId != null) {
              debugPrint('Navigate to complaint with comment: $complaintId');
            }
            break;
          
          case 'announcement_created':
            // Navigate to announcements
            debugPrint('Navigate to announcements');
            break;
          
          default:
            // Navigate to notifications list
            debugPrint('Navigate to notifications list');
            break;
        }
      } catch (e) {
        debugPrint('Navigation error: $e');
      }
    });
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    // Handle navigation
  }

  // Save FCM token to local storage
  Future<void> _saveFCMToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.fcmTokenKey, token);
  }

  // Get saved FCM token
  Future<String?> getFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.fcmTokenKey);
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
}
