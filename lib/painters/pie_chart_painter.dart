
// =====================================
// lib/painters/pie_chart_painter.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/sales_data.dart';

class PieChartPainter extends CustomPainter {
  final List<MonthlyData> data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20;

    double total = data.fold(0, (sum, item) => sum + item.value);
    double startAngle = -pi / 2;

    for (var item in data) {
      double sweepAngle = (item.value / total) * 2 * pi;

      // Create gradient shader
      final gradient = RadialGradient(
        colors: [
          item.color,
          item.color.withOpacity(0.7),
        ],
        center: Alignment.center,
        radius: 0.8,
      );

      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      // Draw shadow
      final shadowPaint = Paint()
        ..color = item.color.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center + Offset(2, 2), radius: radius),
        startAngle,
        sweepAngle,
        true,
        shadowPaint,
      );

      // Draw main arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle for donut effect
    final centerPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.4));

    canvas.drawCircle(center, radius * 0.4, centerPaint);

    // Draw center border
    final centerBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius * 0.4, centerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}