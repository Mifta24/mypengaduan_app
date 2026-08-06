import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../main.dart' show navigatorKey;
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'notification_service.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationService _notificationService;

  static const _channelId = 'high_importance_channel';
  static const _channelName = 'High Importance Notifications';
  static const _channelDesc =
      'This channel is used for important notifications.';

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

    debugPrint(
        '🔔 Notification permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('❌ User denied notification permission');
      return; // Stop jika permission ditolak
    }

    // Initialize local notifications
    // '@drawable/ic_notification' is a white monochrome icon required for Android notification bar
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    debugPrint('✅ Local notifications initialized');

    // Create notification channel for Android (wajib untuk Android 8+)
    // Untuk custom sound: taruh file .ogg/.mp3 di android/app/src/main/res/raw/
    // lalu uncomment baris sound di bawah dan ganti 'notification_sound' dengan nama file (tanpa ekstensi)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      // sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF1E6B3A), // Hijau forest - sesuai branding app
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
      debugPrint('✅ Notification channel created: $_channelId');
    }

    // Paksa FCM untuk tidak menampilkan notifikasi otomatis di foreground
    // Biar kita yang handle via flutter_local_notifications
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

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
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
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

    final RemoteNotification? notification = message.notification;

    // Tentukan judul dan body: prioritaskan notification block, fallback ke data
    final String title = notification?.title ??
        message.data['title'] as String? ??
        'Notifikasi Baru';
    final String body = notification?.body ??
        message.data['body'] as String? ??
        message.data['message'] as String? ??
        '';

    // Tampilkan local notification apapun kondisinya
    // (baik notification-message maupun data-only message dari backend)
    debugPrint('📲 Showing local notification: "$title" - "$body"');
    _showLocalNotification(
      id: message.hashCode,
      title: title,
      body: body,
      payload: message.data.toString(),
    );

    // Refresh badge unread count di UI
    final context = navigatorKey.currentContext;
    if (context != null) {
      try {
        Provider.of<NotificationProvider>(context, listen: false)
            .loadNotifications(refresh: true);
      } catch (e) {
        debugPrint('Failed to refresh notification provider: $e');
      }
    }

    _refreshProfileIfVerificationChanged(message.data['type'] as String?);
  }

  /// Status verifikasi user berubah (diverifikasi/ditolak admin) → refresh
  /// data user supaya UI (mis. tombol buat pengaduan) langsung update.
  void _refreshProfileIfVerificationChanged(String? type) {
    if (type != AppConfig.notificationUserVerified &&
        type != AppConfig.notificationUserVerificationRejected &&
        type != AppConfig.notificationUserVerificationUpdated) {
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null) return;
    try {
      Provider.of<AuthProvider>(context, listen: false).refreshProfile();
    } catch (e) {
      debugPrint('Failed to refresh auth profile: $e');
    }
  }

  // Tampilkan local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      // Small icon: putih monochrome untuk status bar (wajib per Android guidelines)
      icon: '@drawable/ic_notification',
      color: const Color(0xFF1E6B3A), // Hijau forest - warna branding app
      // Large icon: logo app berwarna tampil di body notifikasi
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      playSound: true,
      // sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      showWhen: true,
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
        contentTitle: title,
        htmlFormatContentTitle: false,
      ),
    );
    final notifDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(id, title, body, notifDetails,
        payload: payload);
    debugPrint('✅ Local notification shown (id=$id)');
  }

  // Handle notification tap (FCM background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.data}');

    final type = message.data['type'] as String?;
    final data = message.data;

    // Delay agar app fully mounted
    Future.delayed(const Duration(milliseconds: 800), () {
      _navigateFromNotification(type: type, data: data);
    });
  }

  // Handle local notification tap (saat app foreground)
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Local notification tapped: ${response.payload}');
    // payload belum diparse, arahkan ke notifikasi list
    Future.delayed(const Duration(milliseconds: 300), () {
      _navigateFromNotification(type: null, data: const {});
    });
  }

  /// Navigasi berdasarkan tipe notifikasi
  void _navigateFromNotification({
    required String? type,
    required Map<String, dynamic> data,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('⚠️ Navigator context null, skip navigation');
      return;
    }

    try {
      switch (type) {
        // Notifikasi status verifikasi akun (diverifikasi/ditolak admin)
        case AppConfig.notificationUserVerified:
        case AppConfig.notificationUserVerificationRejected:
        case AppConfig.notificationUserVerificationUpdated:
          debugPrint('➡️ Navigate to home (verification status changed)');
          _refreshProfileIfVerificationChanged(type);
          context.go('/home');
          break;

        // Notifikasi untuk USER: status complaint berubah / admin reply
        case AppConfig.notificationStatusChanged:
        case AppConfig.notificationAdminResponse:
        case 'complaint_response': // Sesuai dengan backend PHP
        case AppConfig.notificationComplaintResolved:
        case 'complaint_updated':
        case AppConfig.notificationCommentAdded:
          final complaintId = data['complaint_id'];
          if (complaintId != null) {
            debugPrint('➡️ Navigate to complaint detail: $complaintId');
            context.push('/complaint/$complaintId');
          } else {
            context.push('/notifications');
          }
          break;

        // Notifikasi untuk ADMIN: pengaduan baru dibuat
        case AppConfig.notificationComplaintCreated:
          final complaintId = data['complaint_id'];
          if (complaintId != null) {
            debugPrint('➡️ Navigate to complaint detail (admin): $complaintId');
            context.push('/complaint/$complaintId');
          } else {
            context.push('/notifications');
          }
          break;

        // Pengumuman baru
        case AppConfig.notificationAnnouncementCreated:
          debugPrint('➡️ Navigate to announcements');
          context.push('/announcements/list');
          break;

        // Default: buka halaman notifikasi
        default:
          debugPrint('➡️ Navigate to notifications list');
          context.push('/notifications');
          break;
      }
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
    }
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

  // Re-register FCM token ke backend setelah login
  Future<void> reRegisterToken() async {
    final token = await getFCMToken();
    if (token != null) {
      debugPrint('🔄 [FCMService] Re-registering FCM token after login...');
      final success = await _notificationService.registerFCMToken(token);
      debugPrint(success
          ? '✅ FCM Token re-registered successfully'
          : '⚠️ FCM Token re-registration failed');
    }
  }

  // Cek notifikasi unread setelah login dan tampilkan sebagai local notification
  // Dipanggil dari AuthProvider setelah login berhasil
  Future<void> checkUnreadAndNotify() async {
    debugPrint('🔍 [FCMService] Checking unread notifications after login...');
    try {
      final response = await _notificationService.getNotifications(
        page: 1,
        perPage: 10,
        status: 'unread',
      );

      final unreadList = response.data;
      debugPrint(
          '📬 [FCMService] Found ${unreadList.length} unread notifications');

      if (unreadList.isEmpty) return;

      // Tampilkan notifikasi terbaru saja (maksimal 3 agar tidak spam)
      final toShow = unreadList.take(3).toList();

      for (int i = 0; i < toShow.length; i++) {
        final notif = toShow[i];
        // Delay antar notifikasi agar tidak tumpuk
        await Future.delayed(Duration(milliseconds: i * 600));
        await _showLocalNotification(
          id: notif.id,
          title: notif.title,
          body: notif.body,
          payload: 'type:${notif.type}',
        );
        debugPrint('📲 Shown unread notif: ${notif.title}');
      }
    } catch (e) {
      debugPrint('⚠️ [FCMService] checkUnreadAndNotify error: $e');
      // Jangan crash — ini opsional
    }
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
