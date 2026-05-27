import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../screens/home/landing_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/admin/dashboard/admin_dashboard_screen.dart';
import '../screens/complaints/create_complaint_screen.dart';
import '../screens/complaints/complaint_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/complaints/complaint_list_screen.dart';
import '../screens/notifications/notification_list_screen.dart';
import '../screens/announcements/announcement_list_screen.dart';
import '../screens/faq/faq_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/notifications/notification_settings_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String adminDashboard = '/admin';
  static const String createComplaint = '/create-complaint';
  static const String complaintDetail = '/complaint/:id';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String myComplaints = '/my-complaints';
  static const String notifications = '/notifications';
  static const String announcementsList = '/announcements/list';
  static const String faq = '/faq';
  static const String contact = '/contact';
  static const String forgotPassword = '/forgot-password';
  static const String notificationSettings = '/notification-settings';

  static GoRouter createRouter(
    AuthProvider authProvider, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: splash,
      debugLogDiagnostics: true,
      redirect: (BuildContext context, GoRouterState state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final user = authProvider.user;
        final isAdmin = user?.role == 'admin';
        
        final isSplashRoute = state.matchedLocation == splash;
        final isLandingRoute = state.matchedLocation == landing;
        final isLoginRoute = state.matchedLocation == login;
        final isRegisterRoute = state.matchedLocation == register;
        final isForgotPassRoute = state.matchedLocation == forgotPassword;
        final isAuthRoute = isLoginRoute || isRegisterRoute || isForgotPassRoute||isLandingRoute;
        final isHomeRoute = state.matchedLocation == home;
        final isAdminRoute = state.matchedLocation == adminDashboard;
        
        debugPrint('GoRouter Redirect - Location: ${state.matchedLocation}, Authenticated: $isAuthenticated, Role: ${user?.role}');
        
        // Always allow splash screen - let it handle its own navigation
        if (isSplashRoute) {
          return null;
        }
        
        // Allow direct navigation to home or admin (don't redirect away)
        if (isAuthenticated && (isHomeRoute || isAdminRoute)) {
          return null;
        }
        
        // If not authenticated and trying to access protected route
        if (!isAuthenticated && !isAuthRoute) {
          debugPrint('Not authenticated, redirecting to landing');
          return landing;
        }
        
        // If authenticated and trying to access auth routes, redirect to proper home
        if (isAuthenticated && isAuthRoute) {
          final destination = isAdmin ? adminDashboard : home;
          debugPrint('Authenticated accessing auth route, redirecting to $destination');
          return destination;
        }
        
        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          name: 'splash',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SplashScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: landing,
          name: 'landing',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const LandingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: login,
          name: 'login',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        ),
        GoRoute(
          path: register,
          name: 'register',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const RegisterScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        ),
        GoRoute(
          path: home,
          name: 'home',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: adminDashboard,
          name: 'adminDashboard',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AdminDashboardScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: createComplaint,
          name: 'createComplaint',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const CreateComplaintScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        ),
        GoRoute(
          path: complaintDetail,
          name: 'complaintDetail',
          pageBuilder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return CustomTransitionPage(
              key: state.pageKey,
              child: ComplaintDetailScreen(complaintId: id),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            );
          },
        ),
        GoRoute(
          path: profile,
          name: 'profile',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ProfileScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        ),
        GoRoute(
          path: editProfile,
          name: 'editProfile',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const EditProfileScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        ),
        GoRoute(
          path: myComplaints,
          name: 'myComplaints',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ComplaintListScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        ),
        GoRoute(
          path: announcementsList,
          name: 'announcementsList',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AnnouncementListScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        ),
        GoRoute(
          path: notifications,
          name: 'notifications',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const NotificationListScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        ),
        GoRoute(
          path: faq,
          name: 'faq',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const FaqScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              var tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        ),
        GoRoute(
          path: contact,
          name: 'contact',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ContactScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              var tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        ),
        GoRoute(
          path: forgotPassword,
          name: 'forgotPassword',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ForgotPasswordScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              var tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: Curves.easeOutCubic));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        ),
        GoRoute(
          path: notificationSettings,
          name: 'notificationSettings',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const NotificationSettingsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              var tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: Curves.easeInOut));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
          ),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Halaman tidak ditemukan',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(state.uri.toString()),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(landing),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bgDeep    = AppTheme.bgDeep;
  static const Color _bgDark    = AppTheme.bgDark;
  static const Color _bgMid     = AppTheme.bgMid;
  static const Color _logoGreen = AppTheme.secondary;
  static const Color _leafBadge = AppTheme.primaryLight;
  static const Color _accent    = AppTheme.accent;
  static const Color _leafDecor = AppTheme.primaryDark;

  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );
    _ctrl.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      debugPrint('Before checkAuthStatus - isAuthenticated: ${authProvider.isAuthenticated}');
      await authProvider.checkAuthStatus();
      if (!mounted) return;

      debugPrint('After checkAuthStatus - isAuthenticated: ${authProvider.isAuthenticated}, user: ${authProvider.user?.name}, role: ${authProvider.user?.role}');
      await Future.delayed(const Duration(milliseconds: 200));

      if (authProvider.isAuthenticated) {
        final user = authProvider.user;
        if (user?.role == 'admin') {
          debugPrint('Navigating to ADMIN DASHBOARD');
          if (mounted) context.go(AppRouter.adminDashboard);
        } else {
          debugPrint('Navigating to HOME');
          if (mounted) context.go(AppRouter.home);
        }
      } else {
        debugPrint('User not authenticated, navigating to LANDING');
        if (mounted) context.go(AppRouter.landing);
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) context.go(AppRouter.landing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background ──────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgDeep, _bgDark, _bgMid],
              ),
            ),
          ),

          // ── Leaf decorations ────────────────────────────────
          _leaf(top: 70,  right: 20, size: 60, rot: 0.3),
          _leaf(top: 130, left: 10,  size: 38, rot: -0.5),
          _leaf(top: 250, right: 40, size: 26, rot: 0.9),
          _leaf(top: 400, left: 5,   size: 20, rot: -0.7),
          _leaf(bottom: 220, left: 18,  size: 46, rot: -0.3),
          _leaf(bottom: 150, right: 14, size: 32, rot: 0.6),

          // ── Bottom wave ─────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _SplashWavePainter(),
            ),
          ),

          // ── Main content ────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 32),
                    const Text(
                      'MyPengaduan',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Suara Anda, Perubahan Nyata',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _accent,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 52),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Untuk Lingkungan yang Lebih Baik',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.45),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Glow ring
        Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _logoGreen.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _logoGreen.withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
        // Main circle + megaphone
        Container(
          width: 128,
          height: 128,
          decoration: const BoxDecoration(
            color: _logoGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.campaign_rounded, size: 72, color: Colors.white),
        ),
        // Leaf badge kanan atas
        Positioned(
          top: 4, right: 8,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _leafBadge,
              shape: BoxShape.circle,
              border: Border.all(color: _bgDark, width: 3),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _leaf({
    double? top, double? bottom, double? left, double? right,
    required double size, required double rot,
  }) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Transform.rotate(
        angle: rot,
        child: Icon(Icons.eco_rounded, size: size,
            color: _leafDecor.withValues(alpha: 0.45)),
      ),
    );
  }
}

class _SplashWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void draw(Color color, double y0, double y1, double y2) {
      final p = Paint()..color = color..style = PaintingStyle.fill;
      final path = Path()
        ..moveTo(0, y0 * size.height)
        ..quadraticBezierTo(size.width * 0.25, y1 * size.height,
            size.width * 0.5, y0 * size.height)
        ..quadraticBezierTo(size.width * 0.75, y2 * size.height,
            size.width, y0 * size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, p);
    }

    draw(const Color(0xFF1B5E35).withValues(alpha: 0.25), 0.55, 0.35, 0.75);
    draw(const Color(0xFF1B5E35).withValues(alpha: 0.18), 0.72, 0.52, 0.88);
    draw(const Color(0xFF0D2B1A).withValues(alpha: 0.60), 0.85, 0.70, 0.95);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
