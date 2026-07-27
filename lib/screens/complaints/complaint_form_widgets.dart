import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ComplaintVisibilitySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const ComplaintVisibilitySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _VisibilityOption(
          value: 'public',
          groupValue: value,
          icon: Icons.public_rounded,
          title: 'Publik',
          description:
              'Isi dan progres dapat dilihat semua orang. Identitas Anda tetap dirahasiakan.',
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
        _VisibilityOption(
          value: 'private',
          groupValue: value,
          icon: Icons.lock_outline_rounded,
          title: 'Privat',
          description:
              'Hanya Anda dan petugas berwenang yang dapat melihat pengaduan.',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final IconData icon;
  final String title;
  final String description;
  final ValueChanged<String> onChanged;

  const _VisibilityOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.description,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.07)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? AppTheme.primary : AppTheme.border,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 4),
            Icon(icon,
                size: 21,
                color: selected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      height: 1.4,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────
class ComplaintStepIndicator extends StatelessWidget {
  final int current; // 1-based
  const ComplaintStepIndicator({super.key, required this.current});

  static const _steps = ['Informasi', 'Detail', 'Konfirmasi'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final passed = (i ~/ 2) + 1 < current;
            return Expanded(
              child: Container(
                  height: 2,
                  color: passed ? AppTheme.primary : AppTheme.border),
            );
          }
          final step = i ~/ 2 + 1;
          final isActive = step == current;
          final isDone = step < current;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (isActive || isDone)
                      ? AppTheme.primary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isActive || isDone)
                        ? AppTheme.primary
                        : AppTheme.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text('$step',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color:
                                isActive ? Colors.white : Colors.grey.shade400,
                          )),
                ),
              ),
              const SizedBox(height: 4),
              Text(_steps[step - 1],
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppTheme.primary : Colors.grey.shade400,
                  )),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Image Source Bottom Sheet ────────────────────────────────────────────────
class ImageSourceSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const ImageSourceSheet(
      {super.key, required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('Pilih Sumber Gambar',
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            _tile(context, Icons.camera_alt_rounded, 'Kamera', onCamera),
            _tile(context, Icons.photo_library_rounded, 'Galeri', onGallery),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _tile(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 22),
      ),
      title: Text(label,
          style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600)),
      onTap: () {
        context.pop();
        onTap();
      },
    );
  }
}

// ─── Dashed Border Painter ────────────────────────────────────────────────────
class DashedBorderPainter extends CustomPainter {
  final Color color;
  const DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashW = 6.0;
    const dashS = 4.0;
    const r = 10.0;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(r)));

    final dest = Path();
    for (final m in path.computeMetrics()) {
      double d = 0;
      bool draw = true;
      while (d < m.length) {
        final len = draw ? dashW : dashS;
        if (draw) dest.addPath(m.extractPath(d, d + len), Offset.zero);
        d += len;
        draw = !draw;
      }
    }
    canvas.drawPath(dest, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
