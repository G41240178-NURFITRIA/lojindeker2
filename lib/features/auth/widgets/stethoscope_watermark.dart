import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Renders the subtle stethoscope line art watermark seen at the bottom of the login screen
class StethoscopeWatermark extends StatelessWidget {
  final double height;
  final Color? color;

  const StethoscopeWatermark({
    super.key,
    this.height = 280,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.watermarkRed.withValues(alpha: 0.18);
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _StethoscopePainter(color: effectiveColor),
        ),
      ),
    );
  }
}

class _StethoscopePainter extends CustomPainter {
  final Color color;

  _StethoscopePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final centerX = w * 0.48;

    // 1. Top Binaural Eartips (left and right)
    final leftEartip = Offset(centerX - 42, h * 0.08);
    final rightEartip = Offset(centerX + 42, h * 0.08);

    // Eartip caps
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: leftEartip, width: 16, height: 6),
        const Radius.circular(3),
      ),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: rightEartip, width: 16, height: 6),
        const Radius.circular(3),
      ),
      fillPaint,
    );

    // 2. Binaural Spring / Cross Bar
    final springPath = Path();
    springPath.moveTo(centerX - 46, h * 0.12);
    springPath.lineTo(centerX + 46, h * 0.12);
    canvas.drawPath(springPath, strokePaint..strokeWidth = 4.5);

    // 3. Binaural Tubing (U-shaped arch coming together)
    strokePaint.strokeWidth = 6.5;
    final uTubePath = Path();
    // Left ear tube
    uTubePath.moveTo(leftEartip.dx, leftEartip.dy + 3);
    uTubePath.cubicTo(
      centerX - 40, h * 0.22,
      centerX - 30, h * 0.32,
      centerX, h * 0.35,
    );
    // Right ear tube
    uTubePath.moveTo(rightEartip.dx, rightEartip.dy + 3);
    uTubePath.cubicTo(
      centerX + 40, h * 0.22,
      centerX + 30, h * 0.32,
      centerX, h * 0.35,
    );
    canvas.drawPath(uTubePath, strokePaint);

    // 4. Flexible Long Tubing with graceful loop down to chest piece
    final longTubePath = Path();
    longTubePath.moveTo(centerX, h * 0.35);
    longTubePath.cubicTo(
      centerX, h * 0.45,
      centerX - 35, h * 0.50,
      centerX - 40, h * 0.65,
    );
    longTubePath.cubicTo(
      centerX - 45, h * 0.85,
      centerX + 10, h * 0.98,
      centerX + 35, h * 0.95,
    );
    longTubePath.cubicTo(
      centerX + 58, h * 0.92,
      centerX + 65, h * 0.82,
      centerX + 70, h * 0.74,
    );
    canvas.drawPath(longTubePath, strokePaint);

    // 5. Stethoscope Chest Piece (Circular Diaphragm & Bell)
    final chestPieceCenter = Offset(centerX + 70, h * 0.73);
    // Outer rim
    canvas.drawCircle(chestPieceCenter, 18, strokePaint);
    // Inner center ring
    canvas.drawCircle(chestPieceCenter, 8, strokePaint..strokeWidth = 4.0);

    // 6. Subtle ground curve/shadow across the bottom
    final groundPaint = Paint()
      ..color = color.withValues(alpha: (color.a * 0.6).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final groundPath = Path();
    groundPath.moveTo(0, h * 0.96);
    groundPath.quadraticBezierTo(w * 0.5, h * 0.93, w, h * 0.98);
    groundPath.lineTo(w, h);
    groundPath.lineTo(0, h);
    groundPath.close();
    canvas.drawPath(groundPath, groundPaint);
  }

  @override
  bool shouldRepaint(covariant _StethoscopePainter oldDelegate) =>
      oldDelegate.color != color;
}
