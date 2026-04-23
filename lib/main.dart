import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/complaint_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/category_provider.dart';
import 'providers/reports_provider.dart';
import 'services/auth_service.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

/// Navigator key global — digunakan FCMService untuk navigate tanpa context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// FCM Service global — bisa dipanggil setelah login untuk check unread notif
FCMService? fcmService;

// Top-level function for background FCM messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message: ${message.messageId}');
  debugPrint('Background message data: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);
  
  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue without Firebase for web testing
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FCMService? _fcmService;

  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    try {
      // Wait a bit for providers to be ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        final authService = AuthService();
        final notificationService = NotificationService(authService);
        _fcmService = FCMService(notificationService);
        fcmService = _fcmService; // expose global
        
        // Initialize FCM
        await _fcmService!.initialize();
        
        debugPrint('FCM Service initialized successfully');

        // Listen ke perubahan auth — saat login berhasil, cek unread notif
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          authProvider.addListener(() {
            if (authProvider.isAuthenticated) {
              // Delay sedikit agar token backend sudah terdaftar
              Future.delayed(const Duration(seconds: 2), () {
                _fcmService?.checkUnreadAndNotify();
              });
            }
          });
        }
      }
    } catch (e) {
      debugPrint('FCM initialization error: $e');
      // Continue without FCM
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => ComplaintProvider(AuthService()),
          lazy: true, // Load only when needed
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(AuthService()),
          lazy: true, // Load only when needed
        ),
        ChangeNotifierProvider(
          create: (_) => AnnouncementProvider(AuthService()),
          lazy: true, // Load only when needed
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(AuthService()),
          lazy: true, // Load only when needed
        ),
        ChangeNotifierProvider(
          create: (_) => ReportsProvider(),
          lazy: true,
        ),
      ],
      child: Builder(
        builder: (context) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          return MaterialApp.router(
            title: 'MyPengaduan',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: AppRouter.createRouter(authProvider),
          );
        },
      ),
    );
  }
}
