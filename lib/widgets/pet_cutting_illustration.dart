import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'pet_planter_parts.dart';

/// First-step style preview only. Geometry and motion parameters stay shared;
/// the other five steps continue using their existing painters until approved.
abstract final class PetCuttingStyle {
  static const ink = Color(0xFF183D58);
  static const plastic = Color(0xB3BFE7F5);
  static const cap = Color(0xFF80B5D7);
  static const metal = Color(0xFFE0E7E8);
  static const handle = Color(0xFFEA9483);
  static const outlineWidth = 5.5;
}

Paint _outline([double width = PetCuttingStyle.outlineWidth]) => Paint()
  ..color = PetCuttingStyle.ink
  ..strokeWidth = width
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

class PetCuttingBottlePainter extends CustomPainter {
  const PetCuttingBottlePainter({required this.upper, required this.separated});
  final bool upper, separated;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (upper) canvas.translate(160, 180);
    final fill = upper
        ? PetPlanterGeometry.upper()
        : PetPlanterGeometry.lower();
    final contour = upper
        ? PetPlanterGeometry.upper(closed: separated)
        : PetPlanterGeometry.lower(closed: separated);
    canvas.drawPath(fill, Paint()..color = PetCuttingStyle.plastic);
    canvas.drawPath(contour, _outline());
    if (upper) {
      final lid = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-26, -126, 52, 16),
        const Radius.circular(4),
      );
      canvas.drawRRect(lid, Paint()..color = PetCuttingStyle.cap);
      canvas.drawRRect(lid, _outline());
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PetCuttingBottlePainter oldDelegate) =>
      upper != oldDelegate.upper || separated != oldDelegate.separated;
}

class PetCuttingGuidePainter extends CustomPainter {
  const PetCuttingGuidePainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    for (var x = 106.0; x < 215; x += 12) {
      canvas.drawLine(
        Offset(x, 180),
        Offset(math.min(x + 6, 215), 180),
        _outline(3.5),
      );
    }
    if (progress > 0) {
      canvas.drawLine(
        const Offset(215, 180),
        Offset(215 - 110 * progress, 180),
        _outline(3.5),
      );
    }
  }

  @override
  bool shouldRepaint(PetCuttingGuidePainter oldDelegate) =>
      progress != oldDelegate.progress;
}

class PetCuttingScissorsPainter extends CustomPainter {
  const PetCuttingScissorsPainter(this.opening);
  final double opening;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(
      PetPlanterGeometry.scissorsTip.dx + 24,
      PetPlanterGeometry.scissorsTip.dy,
    );
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      // The previous scissors use precisely these hinge and opening values.
      canvas.rotate(side * (.1 + .3 * opening));
      canvas.scale(1, side);
      final blade = Path()
        ..moveTo(-25, 0)
        ..quadraticBezierTo(-24, -3, -18, -4)
        ..lineTo(8, -5)
        ..lineTo(15, 0)
        ..lineTo(8, 5)
        ..lineTo(-18, 4)
        ..quadraticBezierTo(-24, 3, -25, 0)
        ..close();
      canvas.drawPath(blade, Paint()..color = PetCuttingStyle.metal);
      canvas.drawPath(blade, _outline(4.2));

      final handle = Path()
        ..fillType = PathFillType.evenOdd
        ..moveTo(8, -4)
        ..quadraticBezierTo(16, -3, 20, 0)
        ..cubicTo(27, -4, 39, -2, 44, 7)
        ..cubicTo(50, 18, 42, 29, 31, 27)
        ..quadraticBezierTo(19, 26, 18, 14)
        ..lineTo(8, 4)
        ..close()
        ..addOval(
          Rect.fromCenter(center: const Offset(33, 12), width: 16, height: 12),
        );
      canvas.drawPath(handle, Paint()..color = PetCuttingStyle.handle);
      canvas.drawPath(handle, _outline(4.2));
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, 4, Paint()..color = PetCuttingStyle.ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PetCuttingScissorsPainter oldDelegate) =>
      opening != oldDelegate.opening;
}
