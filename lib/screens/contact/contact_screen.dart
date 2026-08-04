import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const _contacts = [
    _ContactItem(
      icon: Icons.location_on_rounded,
      label: 'Alamat',
      value:
          'Gang Annur 2 RT 05 RW 01, Poris Plawad Utara, Cipondoh, Tangerang, Banten',
      action: null,
    ),
    _ContactItem(
      icon: Icons.phone_rounded,
      label: 'Telepon',
      value: '+62 21 1234 5678',
      action: 'tel',
    ),
    _ContactItem(
      icon: Icons.chat_rounded,
      label: 'WhatsApp',
      value: '+62 812 3456 7890',
      action: 'wa',
    ),
    _ContactItem(
      icon: Icons.email_rounded,
      label: 'Email',
      value: 'admin@mypengaduan.id',
      action: 'email',
    ),
    _ContactItem(
      icon: Icons.access_time_rounded,
      label: 'Jam Operasional',
      value: 'Senin – Jumat, 08.00 – 16.00 WIB',
      action: null,
    ),
  ];

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
                colors: [AppTheme.bgDeep, AppTheme.bgDark, AppTheme.bgMid],
              ),
            ),
          ),
          // ── Leaf decorations ────────────────────────────────
          _leaf(top: 80, right: 16, size: 52, rot: 0.3),
          _leaf(top: 160, left: 6, size: 34, rot: -0.5),
          _leaf(bottom: 140, left: 14, size: 46, rot: -0.3),
          _leaf(bottom: 80, right: 10, size: 32, rot: 0.6),
          // ── Bottom wave ─────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 130),
              painter: _WavePainter(),
            ),
          ),
          // ── Content ─────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    child: Column(
                      children: [
                        _buildLogoSection(),
                        const SizedBox(height: 32),
                        ..._contacts.map((c) => _buildContactCard(context, c)),
                        const SizedBox(height: 24),
                        _buildTagline(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hubungi Kami',
                  style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Text('Kami siap membantu Anda',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppTheme.accent,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Logo
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.support_agent_rounded,
                  size: 58, color: Colors.white),
            ),
            Positioned(
              top: 0,
              right: 2,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.bgDark, width: 2.5),
                ),
                child: const Icon(Icons.chat_bubble_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Tim MyPengaduan',
            style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text('Siap merespons pengaduan Anda',
            style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppTheme.accent,
                fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildContactCard(BuildContext context, _ContactItem item) {
    return GestureDetector(
      onTap: item.action != null ? () => _handleAction(context, item) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: AppTheme.accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label,
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.55))),
                  const SizedBox(height: 2),
                  Text(item.value,
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),
            if (item.action != null) ...[
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.35), size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return Text(
      'Untuk Lingkungan yang Lebih Baik',
      style: GoogleFonts.nunito(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.4),
          fontStyle: FontStyle.italic),
      textAlign: TextAlign.center,
    );
  }

  void _handleAction(BuildContext context, _ContactItem item) {
    // Copy ke clipboard sebagai fallback
    Clipboard.setData(ClipboardData(text: item.value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.label} disalin ke clipboard',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w500)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _leaf(
      {double? top,
      double? bottom,
      double? left,
      double? right,
      required double size,
      required double rot}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: rot,
        child: Icon(Icons.eco_rounded,
            size: size, color: AppTheme.primaryDark.withValues(alpha: 0.4)),
      ),
    );
  }
}

class _ContactItem {
  final IconData icon;
  final String label;
  final String value;
  final String? action;
  const _ContactItem(
      {required this.icon,
      required this.label,
      required this.value,
      this.action});
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void draw(Color color, double y0, double y1, double y2) {
      final p = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final path = Path()
        ..moveTo(0, y0 * size.height)
        ..quadraticBezierTo(size.width * 0.25, y1 * size.height,
            size.width * 0.5, y0 * size.height)
        ..quadraticBezierTo(
            size.width * 0.75, y2 * size.height, size.width, y0 * size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, p);
    }

    draw(const Color(0xFF1B5E35).withValues(alpha: 0.20), 0.55, 0.35, 0.75);
    draw(const Color(0xFF1B5E35).withValues(alpha: 0.15), 0.72, 0.52, 0.88);
    draw(const Color(0xFF0D2B1A).withValues(alpha: 0.55), 0.85, 0.70, 0.95);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
