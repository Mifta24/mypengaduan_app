import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const Color _bgDeep = AppTheme.bgDeep;
  static const Color _bgDark = AppTheme.bgDark;
  static const Color _bgMid = AppTheme.bgMid;
  static const Color _logoGreen = AppTheme.secondary;
  static const Color _leafBadge = AppTheme.primaryLight;
  static const Color _accent = AppTheme.accent;
  static const Color _leafDecor = AppTheme.primaryDark;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgDeep, _bgDark, _bgMid],
              ),
            ),
          ),

          // ── Decorative leaves ────────────────────────────────
          ..._leafDecorations(),

          // ── Bottom wave ──────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _WavePainter(),
            ),
          ),

          // ── Main content ─────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 52),
                        _buildLogo(),
                        const SizedBox(height: 28),
                        _buildTitle(),
                        const SizedBox(height: 48),
                        _buildFeatures(),
                        const SizedBox(height: 36),
                        _buildCTAButtons(context),
                        const SizedBox(height: 20),
                        _buildBottomTagline(),
                        const SizedBox(height: 56),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo: lingkaran megafon + badge daun ─────────────────────
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
                color: _logoGreen.withValues(alpha: 0.35),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
        // Main circle
        Container(
          width: 128,
          height: 128,
          decoration: const BoxDecoration(
            color: _logoGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.campaign_rounded,
            size: 72,
            color: Colors.white,
          ),
        ),
        // Leaf badge kanan atas
        Positioned(
          top: 2,
          right: 10,
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

  // ── Judul & subtitle ─────────────────────────────────────────
  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'MyPengaduan',
          style: GoogleFonts.nunito(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Suara Anda, Perubahan Nyata',
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _accent,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // ── Feature cards ─────────────────────────────────────────────
  Widget _buildFeatures() {
    final features = [
      (
        Icons.add_circle_outline_rounded,
        'Pengaduan Mudah',
        'Ajukan keluhan lewat formulir online yang mudah digunakan'
      ),
      (
        Icons.track_changes_rounded,
        'Tracking Real-time',
        'Pantau status keluhan dengan notifikasi langsung'
      ),
      (
        Icons.bolt_rounded,
        'Respon Cepat',
        'Tim siap merespon keluhan Anda dengan sigap'
      ),
      (
        Icons.chat_bubble_outline_rounded,
        'Transparan',
        'Komunikasi dua arah antara warga dan pengurus'
      ),
    ];

    return Column(
      children: features
          .map((f) => _buildFeatureCard(icon: f.$1, title: f.$2, desc: f.$3))
          .toList(),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CTA Buttons ───────────────────────────────────────────────
  Widget _buildCTAButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => context.go(AppRouter.register),
            style: ElevatedButton.styleFrom(
              backgroundColor: _leafBadge,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Daftar Sekarang',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () => context.go(AppRouter.login),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.35), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Masuk',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Tagline bawah ─────────────────────────────────────────────
  Widget _buildBottomTagline() {
    return Text(
      'Untuk Lingkungan yang Lebih Baik',
      style: GoogleFonts.nunito(
        fontSize: 13,
        color: Colors.white.withValues(alpha: 0.45),
        fontStyle: FontStyle.italic,
      ),
      textAlign: TextAlign.center,
    );
  }

  // ── Dekorasi daun di background ──────────────────────────────
  List<Widget> _leafDecorations() {
    final leaves = [
      (top: 60.0, right: 18.0, left: null, bottom: null, size: 64.0, rot: 0.3),
      (top: 110.0, left: 8.0, right: null, bottom: null, size: 40.0, rot: -0.5),
      (top: 220.0, right: 35.0, left: null, bottom: null, size: 28.0, rot: 0.9),
      (top: 380.0, left: 4.0, right: null, bottom: null, size: 22.0, rot: -0.7),
      (
        top: null,
        bottom: 220.0,
        left: 16.0,
        right: null,
        size: 48.0,
        rot: -0.3
      ),
      (top: null, bottom: 160.0, right: 12.0, left: null, size: 34.0, rot: 0.6),
    ];

    return leaves.map((l) {
      return Positioned(
        top: l.top,
        bottom: l.bottom,
        left: l.left,
        right: l.right,
        child: Transform.rotate(
          angle: l.rot,
          child: Icon(
            Icons.eco_rounded,
            size: l.size,
            color: _leafDecor.withValues(alpha: 0.45),
          ),
        ),
      );
    }).toList();
  }
}

// ── Wave painter ──────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void drawWave(Color color, double yStart, double yMid1, double yMid2) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final path = Path()
        ..moveTo(0, yStart * size.height)
        ..quadraticBezierTo(size.width * 0.25, yMid1 * size.height,
            size.width * 0.5, yStart * size.height)
        ..quadraticBezierTo(size.width * 0.75, yMid2 * size.height, size.width,
            yStart * size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }

    drawWave(const Color(0xFF1B5E35).withValues(alpha: 0.25), 0.55, 0.35, 0.75);
    drawWave(const Color(0xFF1B5E35).withValues(alpha: 0.18), 0.72, 0.52, 0.88);
    drawWave(const Color(0xFF0D2B1A).withValues(alpha: 0.60), 0.85, 0.70, 0.95);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
