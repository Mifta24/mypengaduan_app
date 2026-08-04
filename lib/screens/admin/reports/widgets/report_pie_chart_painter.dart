import 'dart:math' as math;
import 'package:flutter/material.dart';

class ReportPieChartPainter extends CustomPainter {
  final List<(double, Color)> segments;
  const ReportPieChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold(0.0, (s, e) => s + e.$1);
    if (total == 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.28;
    final radius = size.width / 2 * 0.72;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweep = seg.$1 / total * 2 * math.pi;
      paint.color = seg.$2;
      canvas.drawArc(rect, startAngle, sweep - 0.04, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant ReportPieChartPainter old) =>
      old.segments != segments;
}
