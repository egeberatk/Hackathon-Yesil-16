import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../animations/motion_sequence.dart';
import '../core/app_theme.dart';

/// All six scenes use the same two bottle paths, pivot and reservoir geometry.
/// Dimensions are diagram units, scaled together without changing proportions.
class PetPlanterScene extends StatelessWidget {
  const PetPlanterScene({
    super.key,
    required this.frame,
    required this.stepIndex,
  });
  final MotionFrame frame;
  final int stepIndex;
  static const cutOrigin = Offset(160, 180);
  // Rotate about the upper part's centre, keeping its entire swept area above
  // the reservoir rim. Only then translate the inverted neck down into it.
  static const pivot = Offset(160, 125);
  static const waterSurface = 268.0;
  static const stripEnd = Offset(160, 282);

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.contain,
    child: SizedBox(
      width: 320,
      height: 330,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(willChange: true, painter: _ReservoirPainter(frame)),
          MotionTransform(
            pose: frame['upper'],
            pivot: pivot,
            child: CustomPaint(
              willChange: true,
              painter: _UpperPainter(frame, stepIndex),
            ),
          ),
          if (stepIndex == 1 || stepIndex == 2)
            MotionTransform(
              pose: frame['cap'],
              pivot: const Offset(160, 65),
              child: CustomPaint(
                willChange: true,
                painter: _CapPainter(frame['hole'].amount),
              ),
            ),
          CustomPaint(
            willChange: true,
            painter: _ConnectionsPainter(frame, stepIndex),
          ),
        ],
      ),
    ),
  );
}

const _ink = AppTheme.primary;
const _water = Color(0xFF7FBFD0);
const _soil = Color(0xFF83614A);
const _strip = Color(0xFFD7B571);

Paint _stroke(Color color, [double width = 2.5]) => Paint()
  ..color = color
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..style = PaintingStyle.stroke;

Path _upperPath() => Path()
  ..moveTo(-55, 0)
  ..lineTo(-50, -50)
  ..cubicTo(-49, -71, -14, -72, -14, -90)
  ..lineTo(-14, -110)
  ..lineTo(14, -110)
  ..lineTo(14, -90)
  ..cubicTo(14, -72, 49, -71, 50, -50)
  ..lineTo(55, 0)
  ..close();

Path _lowerPath() => Path()
  ..moveTo(105, 180)
  ..lineTo(110, 280)
  ..quadraticBezierTo(110, 290, 120, 290)
  ..lineTo(200, 290)
  ..quadraticBezierTo(210, 290, 210, 280)
  ..lineTo(215, 180)
  ..close();

void _cap(Canvas canvas, double hole) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-16, -120, 32, 10),
      const Radius.circular(3),
    ),
    Paint()..color = _ink,
  );
  canvas.drawLine(
    const Offset(-10, -117),
    const Offset(10, -117),
    _stroke(AppTheme.secondary, 1),
  );
  if (hole > 0) {
    canvas.drawCircle(
      const Offset(0, -115),
      3 * hole,
      Paint()..color = Colors.white,
    );
  }
}

class _ReservoirPainter extends CustomPainter {
  _ReservoirPainter(this.frame);
  final MotionFrame frame;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      const Rect.fromLTWH(85, 299, 150, 12),
      Paint()..color = _ink.withValues(alpha: .05),
    );
    final lower = _lowerPath();
    canvas.drawPath(
      lower,
      Paint()..color = Colors.white.withValues(alpha: .65),
    );
    final amount = frame['water'].amount;
    if (amount > 0) {
      final surface = 290 - (290 - PetPlanterScene.waterSurface) * amount;
      canvas.save();
      canvas.clipPath(lower);
      canvas.drawRect(
        Rect.fromLTRB(105, surface, 215, 290),
        Paint()..color = _water.withValues(alpha: .65),
      );
      canvas.drawLine(
        Offset(106, surface),
        Offset(214, surface),
        _stroke(_water, 2),
      );
      canvas.restore();
    }
    canvas.drawPath(lower, _stroke(_ink));
    canvas.drawLine(
      const Offset(108, 206),
      const Offset(111, 259),
      _stroke(Colors.white, 3),
    );
    if (frame['edge'].amount > 0) {
      canvas.drawLine(
        const Offset(105, 180),
        const Offset(215, 180),
        _stroke(AppTheme.accent.withValues(alpha: frame['edge'].amount), 5),
      );
    }
  }

  @override
  bool shouldRepaint(_ReservoirPainter oldDelegate) =>
      oldDelegate.frame != frame;
}

class _UpperPainter extends CustomPainter {
  _UpperPainter(this.frame, this.stepIndex);
  final MotionFrame frame;
  final int stepIndex;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(
      PetPlanterScene.cutOrigin.dx,
      PetPlanterScene.cutOrigin.dy,
    );
    final upper = _upperPath();
    canvas.drawPath(
      upper,
      Paint()..color = Colors.white.withValues(alpha: .48),
    );
    final soil = frame['soil'].amount;
    if (soil > 0) {
      canvas.save();
      canvas.clipPath(upper);
      // After inversion the fill rises from the shoulder towards the open rim.
      final surface = -70 + 55 * soil;
      canvas.drawRect(
        Rect.fromLTRB(-55, -78, 55, surface),
        Paint()..color = _soil,
      );
      for (var i = 0; i < 12; i++) {
        final x = -32.0 + (i % 4) * 20;
        final y = -60.0 + (i ~/ 4) * 17;
        if (y < surface) {
          canvas.drawCircle(
            Offset(x, y),
            1.8,
            Paint()..color = const Color(0xFFB28B68),
          );
        }
      }
      canvas.restore();
    }
    canvas.drawPath(upper, _stroke(_ink));
    canvas.drawLine(
      const Offset(-42, -20),
      const Offset(-39, -47),
      _stroke(Colors.white, 3),
    );
    if (stepIndex != 1 && stepIndex != 2) _cap(canvas, frame['hole'].amount);
    final edge = frame['edge'].amount;
    if (edge > 0) {
      canvas.drawLine(
        const Offset(-55, 0),
        const Offset(55, 0),
        _stroke(AppTheme.accent.withValues(alpha: edge), 5),
      );
    }
    final plant = frame['plant'].amount;
    if (plant > 0) {
      canvas.drawLine(
        const Offset(0, -15),
        Offset(0, -15 + 61 * plant),
        _stroke(_ink, 3),
      );
      if (plant > .4) {
        final leaves = Path()
          ..moveTo(0, 14)
          ..quadraticBezierTo(30, 8, 30, 32)
          ..quadraticBezierTo(8, 35, 0, 14)
          ..moveTo(0, 28)
          ..quadraticBezierTo(-28, 24, -27, 46)
          ..quadraticBezierTo(-6, 47, 0, 28);
        canvas.drawPath(
          leaves,
          Paint()..color = AppTheme.secondary.withValues(alpha: plant),
        );
        canvas.drawPath(leaves, _stroke(_ink, 1.5));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_UpperPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.stepIndex != stepIndex;
}

class _CapPainter extends CustomPainter {
  _CapPainter(this.hole);
  final double hole;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(160, 180);
    _cap(canvas, hole);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CapPainter oldDelegate) => oldDelegate.hole != hole;
}

class _ConnectionsPainter extends CustomPainter {
  _ConnectionsPainter(this.frame, this.stepIndex);
  final MotionFrame frame;
  final int stepIndex;
  Offset _world(Offset point) => transformMotionPoint(
    point + PetPlanterScene.cutOrigin,
    PetPlanterScene.pivot,
    frame['upper'],
  );
  @override
  void paint(Canvas canvas, Size size) {
    if (stepIndex == 0) {
      final alpha = (1 - frame['upper'].offset.dy.abs() / 55).clamp(0.0, 1.0);
      for (var x = 92.0; x < 230; x += 12) {
        canvas.drawLine(
          Offset(x, 180),
          Offset(x + 6, 180),
          _stroke(AppTheme.accent.withValues(alpha: alpha), 2),
        );
      }
    }
    final strip = frame['strip'].amount;
    if (strip > 0) {
      var inside = _world(const Offset(12, -40));
      var mouth = _world(const Offset(0, -115));
      var control = _world(const Offset(0, -75));
      if (stepIndex == 2) {
        mouth = const Offset(160, 65) + frame['cap'].offset;
        final attached = frame['cap'].offset.dx.abs() < .01
            ? ((frame['cap'].offset.dy + 60) / 25).clamp(0.0, 1.0)
            : 0.0;
        inside = Offset.lerp(mouth + const Offset(12, 40), inside, attached)!;
        control = Offset.lerp(mouth + const Offset(0, 20), control, attached)!;
      }
      final bend = (1 + math.cos(frame['upper'].angle)) / 2;
      // A flexible loose end hangs outside the separated part; once inverted
      // it extends through the cap down into the reservoir, never through PET.
      final end = Offset(160 - 90 * bend, 282 - 90 * bend);
      final path = Path()
        ..moveTo(inside.dx, inside.dy)
        ..quadraticBezierTo(control.dx, control.dy, mouth.dx, mouth.dy)
        ..cubicTo(
          mouth.dx - 110 * bend,
          mouth.dy - 35 * bend,
          end.dx - 15 * bend,
          end.dy - 45,
          end.dx,
          end.dy,
        );
      final metric = path.computeMetrics().first;
      final shown = metric.extractPath(0, metric.length * strip);
      canvas.drawPath(shown, _stroke(_strip, 6));
      canvas.drawPath(shown, _stroke(const Color(0xFFFFF0CC), 2));
    }
    if (frame.activeKind == MotionKind.pour) {
      if (frame['soil'].amount > 0 && frame['soil'].amount < 1) {
        // Soil drops into the upward-facing cut opening.
        for (var i = 0; i < 6; i++) {
          final y = 65 + ((frame.activeProgress * 95 + i * 13) % 80);
          canvas.drawCircle(
            Offset(143 + (i % 3) * 16.0, y),
            2.5,
            Paint()..color = _soil,
          );
        }
      } else if (frame['water'].amount > 0 && frame['water'].amount < 1) {
        // A narrow pour runs beside the upper piece into the lower vessel.
        final stream = Path()
          ..moveTo(245, 163)
          ..quadraticBezierTo(220, 160, 210, 180)
          ..lineTo(207, 274);
        canvas.drawPath(stream, _stroke(_water, 3));
        // A tilted cup has an open mouth; the stream leaves its lower lip.
        final cup = Path()
          ..moveTo(256, 136)
          ..lineTo(279, 145)
          ..quadraticBezierTo(283, 147, 281, 151)
          ..lineTo(273, 171)
          ..quadraticBezierTo(271, 175, 267, 173)
          ..lineTo(245, 163);
        canvas.drawPath(cup, _stroke(_ink, 2));
      } else if (frame['moisture'].amount > 0 && frame['moisture'].amount < 1) {
        for (var i = 0; i < 3; i++) {
          final y = 105 + ((frame.activeProgress * 50 + i * 12) % 40);
          canvas.drawLine(
            Offset(135 + i * 24.0, y),
            Offset(135 + i * 24.0, y + 5),
            _stroke(_water, 2),
          );
        }
      }
    }
    if (stepIndex >= 4 && frame['water'].amount > 0) {
      canvas.drawLine(
        const Offset(220, 268),
        const Offset(239, 268),
        _stroke(_water, 1.5),
      );
      canvas.drawLine(
        const Offset(220, 260),
        const Offset(226, 260),
        _stroke(AppTheme.accent, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(_ConnectionsPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.stepIndex != stepIndex;
}
