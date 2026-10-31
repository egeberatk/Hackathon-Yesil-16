import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../animations/motion_sequence.dart';
import '../animations/workshop_steps.dart';

part 'workshop_package2_parts.dart';
part 'workshop_package3_parts.dart';

/// Shared painter and vector parts for the workshop recipe registry.
class WorkshopStepScene extends StatelessWidget {
  const WorkshopStepScene({super.key, required this.step, required this.frame});
  final WorkshopStep step;
  final MotionFrame frame;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ScenePainter(step, frame));
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.step, this.frame);
  final WorkshopStep step;
  final MotionFrame frame;
  static const ink = Color(0xFF193B52),
      blue = Color(0xFFC6E8F3),
      tan = Color(0xFFE4C6A0),
      green = Color(0xFF95D5B2),
      coral = Color(0xFFE9A18E);
  Paint get line => Paint()
    ..color = ink
    ..strokeWidth = 4.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  void shape(Canvas c, Path path, Color color) {
    c.drawPath(path, Paint()..color = color);
    c.drawPath(path, line);
  }

  void rect(Canvas c, Rect r, Color color, [double radius = 7]) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, Paint()..color = color);
    c.drawRRect(rr, line);
  }

  void ellipse(Canvas c, Rect r, Color color) {
    c.drawOval(r, Paint()..color = color);
    c.drawOval(r, line);
  }

  void stroke(Canvas c, double x, double y, double x2, double y2) =>
      c.drawLine(Offset(x, y), Offset(x2, y2), line);
  void reveal(Canvas c, Path path, double amount) {
    for (final metric in path.computeMetrics()) {
      c.drawPath(
        metric.extractPath(0, metric.length * amount.clamp(0, 1)),
        line,
      );
    }
  }

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 320, size.height / 330);
    c.clipRect(const Rect.fromLTWH(0, 0, 320, 330));
    for (final part in step.parts) {
      final pose = frame[part.id];
      if (pose.amount <= 0) continue;
      c.save();
      c.translate(
        part.position.dx + pose.offset.dx,
        part.position.dy + pose.offset.dy,
      );
      c.rotate(part.angle + pose.angle);
      c.scale(part.scale);
      _object(c, part, pose.amount);
      c.restore();
    }
    c.restore();
  }

  void _object(Canvas c, WorkshopPart part, double amount) {
    switch (part.object) {
      case WorkshopObject.board:
        // Game boards use the same part at a readable flat, square size.
        if (part.id == 'board') {
          rect(c, const Rect.fromLTWH(-100, -100, 200, 200), tan);
        } else {
          rect(c, const Rect.fromLTWH(-118, -12, 236, 24), tan);
        }
      case WorkshopObject.roll:
        rect(c, const Rect.fromLTWH(-23, -43, 46, 94), tan, 5);
        ellipse(
          c,
          const Rect.fromLTWH(-23, -54, 46, 22),
          const Color(0xFFF5E6D1),
        );
        ellipse(
          c,
          const Rect.fromLTWH(-13, -49, 26, 12),
          const Color(0xFFC7A47C),
        );
      case WorkshopObject.box:
        rect(c, const Rect.fromLTWH(-103, -62, 206, 124), tan);
        rect(
          c,
          const Rect.fromLTWH(-85, -45, 170, 86),
          const Color(0xFFF3E8D5),
        );
        stroke(c, -103, 62, -85, 41);
        stroke(c, 103, 62, 85, 41);
      case WorkshopObject.bottle:
        shape(
          c,
          Path()
            ..moveTo(-15, -66)
            ..lineTo(-15, -48)
            ..cubicTo(-32, -31, -36, -24, -36, -6)
            ..lineTo(-36, 60)
            ..quadraticBezierTo(-36, 77, -18, 72)
            ..quadraticBezierTo(0, 80, 18, 72)
            ..quadraticBezierTo(36, 77, 36, 60)
            ..lineTo(36, -6)
            ..cubicTo(36, -24, 32, -31, 15, -48)
            ..lineTo(15, -66)
            ..close(),
          blue,
        );
        rect(
          c,
          const Rect.fromLTWH(-19, -80, 38, 16),
          const Color(0xFF86B7D2),
          4,
        );
        for (final y in [0.0, 26.0, 52.0]) {
          stroke(c, -31, y, 31, y);
        }
      case WorkshopObject.cap:
        ellipse(c, const Rect.fromLTWH(-25, -25, 50, 50), blue);
        c.drawOval(
          const Rect.fromLTWH(-18, -18, 36, 36),
          line..strokeWidth = 2.5,
        );
      case WorkshopObject.ball:
        ellipse(c, const Rect.fromLTWH(-24, -24, 48, 48), coral);
        c.drawArc(
          const Rect.fromLTWH(-13, -24, 26, 48),
          -math.pi / 2,
          math.pi,
          false,
          line,
        );
      case WorkshopObject.cup:
        if (part.label == 'front') {
          shape(
            c,
            Path()
              ..moveTo(-55, -24)
              ..lineTo(-41, 52)
              ..quadraticBezierTo(0, 65, 41, 52)
              ..lineTo(55, -24)
              ..quadraticBezierTo(0, -10, -55, -24)
              ..close(),
            const Color(0xFFEAF4ED),
          );
        } else {
          shape(
            c,
            Path()
              ..moveTo(-55, -38)
              ..lineTo(-41, 52)
              ..quadraticBezierTo(0, 65, 41, 52)
              ..lineTo(55, -38)
              ..close(),
            const Color(0xFFEAF4ED),
          );
          ellipse(c, const Rect.fromLTWH(-55, -48, 110, 22), green);
          if (part.angle == 0) {
            c.drawOval(
              const Rect.fromLTWH(-45, -43, 90, 12),
              line..strokeWidth = 2.5,
            );
          }
        }
      case WorkshopObject.yarn:
        ellipse(c, const Rect.fromLTWH(-37, -37, 74, 74), coral);
        for (final offset in [-18.0, 0.0, 18.0]) {
          c.drawPath(
            Path()
              ..moveTo(-28, offset - 12)
              ..quadraticBezierTo(0, offset + 22, 28, offset + 3),
            line..strokeWidth = 3,
          );
        }
        c.drawPath(
          Path()
            ..moveTo(-14, -32)
            ..quadraticBezierTo(24, 0, 8, 33),
          line..strokeWidth = 3,
        );
      case WorkshopObject.thread:
        reveal(
          c,
          Path()
            ..moveTo(12, -18)
            ..cubicTo(45, -50, 65, -21, 72, 8)
            ..cubicTo(80, 35, 95, 30, 113 * amount.clamp(1, 1.2), 65),
          amount,
        );
      case WorkshopObject.pencil:
        rect(
          c,
          const Rect.fromLTWH(-7, -33, 14, 68),
          const Color(0xFFF1D385),
          2,
        );
        shape(
          c,
          Path()
            ..moveTo(-7, -33)
            ..lineTo(0, -49)
            ..lineTo(7, -33)
            ..close(),
          tan,
        );
        stroke(c, 0, -49, 0, -43);
        rect(c, const Rect.fromLTWH(-8, 35, 16, 10), coral, 3);
        stroke(c, -7, 30, 7, 30);
      case WorkshopObject.tape:
        rect(
          c,
          Rect.fromLTWH(-30, -8, 60 * amount.clamp(0, 1), 16),
          const Color(0xFFF3D987),
          3,
        );
      case WorkshopObject.grid:
        final path = Path()
          ..moveTo(-30, -90)
          ..lineTo(-30, 90)
          ..moveTo(30, -90)
          ..lineTo(30, 90)
          ..moveTo(-90, -30)
          ..lineTo(90, -30)
          ..moveTo(-90, 30)
          ..lineTo(90, 30);
        final metrics = path.computeMetrics().toList();
        for (var i = 0; i < metrics.length; i++) {
          final v = (amount * 4 - i).clamp(0.0, 1.0);
          c.drawPath(metrics[i].extractPath(0, metrics[i].length * v), line);
        }
      case WorkshopObject.cross:
        reveal(
          c,
          Path()
            ..moveTo(-11, -11)
            ..lineTo(11, 11)
            ..moveTo(11, -11)
            ..lineTo(-11, 11),
          amount,
        );
      case WorkshopObject.ring:
        c.drawArc(
          const Rect.fromLTWH(-13, -13, 26, 26),
          -math.pi / 2,
          math.pi * 2 * amount.clamp(0, 1),
          false,
          line,
        );
      case WorkshopObject.water:
        rect(
          c,
          Rect.fromLTWH(-30, 13 - 18 * amount, 60, 18 * amount),
          const Color(0xFF82C5E1),
          4,
        );
      case WorkshopObject.distance:
        stroke(c, 0, -43, 0, 43);
        stroke(c, 0, -43, -9, -31);
        stroke(c, 0, -43, 9, -31);
        stroke(c, 0, 43, -9, 31);
        stroke(c, 0, 43, 9, 31);
        if (part.label.isNotEmpty) {
          final text = TextPainter(
            text: TextSpan(
              text: part.label,
              style: const TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          text.paint(c, const Offset(14, -10));
        }
      case WorkshopObject.cloth:
        rect(c, const Rect.fromLTWH(-35, -20, 70, 40), blue);
        stroke(c, -25, -8, 25, -8);
        stroke(c, -25, 8, 25, 8);
      case WorkshopObject.sheet:
      case WorkshopObject.foldingPaper:
      case WorkshopObject.foldingFlap:
      case WorkshopObject.cable:
      case WorkshopObject.frameWrap:
      case WorkshopObject.photo:
      case WorkshopObject.jar:
      case WorkshopObject.paperDot:
      case WorkshopObject.flipCap:
      case WorkshopObject.binocularWrap:
      case WorkshopObject.eggTray:
      case WorkshopObject.stone:
      case WorkshopObject.lid:
      case WorkshopObject.slot:
      case WorkshopObject.coin:
        package2Object(c, part, amount);
      case WorkshopObject.paperPanel:
      case WorkshopObject.accordion:
      case WorkshopObject.receipt:
      case WorkshopObject.shallowFrame:
      case WorkshopObject.cardboardStrip:
      case WorkshopObject.slottedStrip:
      case WorkshopObject.interlock:
      case WorkshopObject.drawerGrid:
      case WorkshopObject.compression:
      case WorkshopObject.petTop:
      case WorkshopObject.petBase:
      case WorkshopObject.cutMark:
      case WorkshopObject.sideCap:
      case WorkshopObject.bagBody:
      case WorkshopObject.bagMouth:
      case WorkshopObject.dryStream:
      case WorkshopObject.dryPile:
      case WorkshopObject.ventHoles:
      case WorkshopObject.suspensionRope:
      case WorkshopObject.hangerRing:
      case WorkshopObject.onion:
      case WorkshopObject.liquidFill:
      case WorkshopObject.pourStream:
      case WorkshopObject.ingredientBottle:
      case WorkshopObject.singleDrop:
      case WorkshopObject.paperCone:
        package3Object(c, part, amount);
      case WorkshopObject.paperCup:
        if (part.label != 'front') {
          shape(
            c,
            Path()
              ..moveTo(-43, -42)
              ..lineTo(43, -42)
              ..lineTo(30, 52)
              ..quadraticBezierTo(0, 60, -30, 52)
              ..close(),
            const Color(0xFFFFF3D5),
          );
          ellipse(
            c,
            const Rect.fromLTWH(-43, -49, 86, 17),
            const Color(0xFFFFFCF4),
          );
        } else {
          shape(
            c,
            Path()
              ..moveTo(-41, -24)
              ..quadraticBezierTo(0, -13, 41, -24)
              ..lineTo(30, 52)
              ..quadraticBezierTo(0, 60, -30, 52)
              ..close(),
            const Color(0xFFFFF3D5),
          );
        }
        stroke(c, -22, -24, -14, 40);
        if (part.label == 'label' || part.label == 'front') {
          for (var i = 0; i < (3 * amount.clamp(0, 1)).ceil(); i++) {
            stroke(c, -7, -7 + i * 12, 21, -7 + i * 12);
          }
        }
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.step != step;
}
