import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../animations/motion_sequence.dart';

/// Flat colours matching the supplied 2D guide, without lighting effects.
abstract final class PetPlanterPalette {
  static const outline = Color(0xFF659DAA);
  static const plastic = Color(0x99C7E6EE);
  static const cap = Color(0xFF508D9B);
  static const water = Color(0xFF82C4DA);
  static const soil = Color(0xFFA08469);
  static const stem = Color(0xFF3B8554);
  static const leaf = Color(0xFF71B584);
  static const darkLeaf = Color(0xFF3B8554);
  static const cloth = Color(0xFFB08B59);
  static const cut = Color(0xFFE57D61);
  static const tool = Color(0xFF63786F);
}

/// Shared paths keep the cut halves and their contents aligned in every step.
abstract final class PetPlanterGeometry {
  static const cutOrigin = Offset(160, 180);
  static const pivot = Offset(160, 125);
  static const scissorsTip = Offset(215, 180);
  static const waterSurface = 268.0;
  static const stripEnd = Offset(160, 282);

  static Path upper({bool closed = true}) {
    final path = Path()
      ..moveTo(-55, 0)
      ..lineTo(-53, -38)
      ..cubicTo(-52, -61, -35, -80, -22, -90)
      ..lineTo(-22, -110)
      ..lineTo(22, -110)
      ..lineTo(22, -90)
      ..cubicTo(35, -80, 52, -61, 53, -38)
      ..lineTo(55, 0);
    if (closed) path.close();
    return path;
  }

  static Path lower({bool closed = true}) {
    final path = Path()
      ..moveTo(105, 180)
      ..lineTo(105, 278)
      ..quadraticBezierTo(105, 290, 117, 290)
      ..lineTo(203, 290)
      ..quadraticBezierTo(215, 290, 215, 278)
      ..lineTo(215, 180);
    if (closed) path.close();
    return path;
  }

  static Offset upperPoint(Offset point, MotionPose pose) =>
      transformMotionPoint(point + cutOrigin, pivot, pose);
}

Paint _line(Color colour, [double width = 1.8]) => Paint()
  ..color = colour
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..style = PaintingStyle.stroke;

void _drawCap(Canvas canvas, double hole) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-26, -120, 52, 10),
      const Radius.circular(3),
    ),
    Paint()..color = PetPlanterPalette.cap,
  );
  if (hole > 0) {
    canvas.drawCircle(
      const Offset(0, -115),
      2.5 * hole,
      Paint()..color = const Color(0xFFF0F6F2),
    );
  }
}

class PetReservoirPainter extends CustomPainter {
  const PetReservoirPainter({required this.separated, required this.edge});
  final bool separated;
  final double edge;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      PetPlanterGeometry.lower(),
      Paint()..color = PetPlanterPalette.plastic,
    );
    canvas.drawPath(
      PetPlanterGeometry.lower(closed: separated),
      _line(PetPlanterPalette.outline),
    );
    if (edge > 0) {
      canvas.drawLine(
        const Offset(105, 180),
        Offset(105 + 110 * edge, 180),
        _line(PetPlanterPalette.cut, 2.4),
      );
    }
  }

  @override
  bool shouldRepaint(PetReservoirPainter oldDelegate) =>
      separated != oldDelegate.separated || edge != oldDelegate.edge;
}

class PetWaterPainter extends CustomPainter {
  const PetWaterPainter(this.amount);
  final double amount;
  @override
  void paint(Canvas canvas, Size size) {
    if (amount <= 0) return;
    final surface = 290 - (290 - PetPlanterGeometry.waterSurface) * amount;
    canvas.save();
    canvas.clipPath(PetPlanterGeometry.lower());
    canvas.drawRect(
      Rect.fromLTRB(106, surface, 214, 289),
      Paint()..color = PetPlanterPalette.water.withValues(alpha: .75),
    );
    canvas.drawLine(
      Offset(106, surface),
      Offset(214, surface),
      _line(PetPlanterPalette.water, 1.3),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PetWaterPainter oldDelegate) =>
      amount != oldDelegate.amount;
}

class PetUpperBottlePainter extends CustomPainter {
  const PetUpperBottlePainter({
    required this.separated,
    required this.edge,
    required this.cap,
    required this.hole,
    this.outlineOnly = false,
  });
  final bool separated, cap, outlineOnly;
  final double edge, hole;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(160, 180);
    if (!outlineOnly) {
      canvas.drawPath(
        PetPlanterGeometry.upper(),
        Paint()..color = PetPlanterPalette.plastic,
      );
    } else {
      canvas.drawPath(
        PetPlanterGeometry.upper(closed: separated),
        _line(PetPlanterPalette.outline),
      );
      if (cap) _drawCap(canvas, hole);
      if (edge > 0) {
        canvas.drawLine(
          const Offset(-55, 0),
          Offset(-55 + 110 * edge, 0),
          _line(PetPlanterPalette.cut, 2.4),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PetUpperBottlePainter oldDelegate) =>
      separated != oldDelegate.separated ||
      edge != oldDelegate.edge ||
      cap != oldDelegate.cap ||
      hole != oldDelegate.hole ||
      outlineOnly != oldDelegate.outlineOnly;
}

class PetCapPainter extends CustomPainter {
  const PetCapPainter(this.hole);
  final double hole;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(160, 180);
    _drawCap(canvas, hole);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PetCapPainter oldDelegate) => hole != oldDelegate.hole;
}

class PetSoilPainter extends CustomPainter {
  const PetSoilPainter(this.amount);
  final double amount;
  @override
  void paint(Canvas canvas, Size size) {
    if (amount <= 0) return;
    canvas.save();
    canvas.translate(160, 180);
    canvas.clipPath(PetPlanterGeometry.upper());
    canvas.drawRect(
      Rect.fromLTRB(-55, -78, 55, -70 + 55 * amount),
      Paint()..color = PetPlanterPalette.soil,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PetSoilPainter oldDelegate) =>
      amount != oldDelegate.amount;
}

class PetPlantPainter extends CustomPainter {
  const PetPlantPainter(this.amount);
  final double amount;
  @override
  void paint(Canvas canvas, Size size) {
    if (amount <= 0) return;
    canvas.save();
    canvas.translate(160, 180);
    // The complete plant moves down as a piece, rather than growing in place.
    canvas.translate(0, 30 * (1 - amount));
    canvas.drawLine(
      const Offset(0, -15),
      const Offset(0, 42),
      _line(PetPlanterPalette.stem.withValues(alpha: amount), 3),
    );
    final right = Path()
      ..moveTo(0, 12)
      ..quadraticBezierTo(28, 12, 30, 34)
      ..quadraticBezierTo(9, 36, 0, 12);
    final left = Path()
      ..moveTo(0, 27)
      ..quadraticBezierTo(-23, 23, -28, 45)
      ..quadraticBezierTo(-6, 47, 0, 27);
    canvas.drawPath(
      right,
      Paint()..color = PetPlanterPalette.leaf.withValues(alpha: amount),
    );
    canvas.drawPath(
      left,
      Paint()..color = PetPlanterPalette.darkLeaf.withValues(alpha: amount),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PetPlantPainter oldDelegate) =>
      amount != oldDelegate.amount;
}

class PetStripPainter extends CustomPainter {
  const PetStripPainter(this.frame, this.stepIndex);
  final MotionFrame frame;
  final int stepIndex;
  Path buildPath() {
    if (frame['strip'].amount <= 0) return Path();
    final upper = frame['upper'];
    Offset world(Offset p) => PetPlanterGeometry.upperPoint(p, upper);
    var inside = world(const Offset(12, -40));
    var control = world(const Offset(0, -75));
    var mouth = world(const Offset(0, -115));
    final bend = (1 + math.cos(upper.angle)) / 2;
    var end = Offset.lerp(
      PetPlanterGeometry.stripEnd,
      const Offset(82, 192),
      bend,
    )!;
    var outside = Offset(mouth.dx - 80 * bend, mouth.dy - 8 * bend);
    var tail = Offset(end.dx, end.dy - 45);
    if (stepIndex == 2) {
      // First translate the whole strip through the detached cap; then let
      // its loose ends flex as the cap is carried over and seated on the neck.
      mouth = const Offset(160, 65) + frame['cap'].offset;
      final seated = frame['stripSeated'].amount;
      inside = Offset.lerp(mouth + const Offset(8, -40), inside, seated)!;
      control = Offset.lerp(mouth + const Offset(4, -20), control, seated)!;
      end = Offset.lerp(
        mouth + const Offset(0, 75),
        const Offset(82, 192),
        seated,
      )!;
      outside = Offset.lerp(
        mouth + const Offset(-4, 25),
        Offset(mouth.dx - 80, mouth.dy - 8),
        seated,
      )!;
      tail = Offset.lerp(
        mouth + const Offset(2, 50),
        const Offset(82, 147),
        seated,
      )!;
      final feed = frame['strip'].offset;
      inside += feed;
      control += feed;
      mouth += feed;
      outside += feed;
      tail += feed;
      end += feed;
    }
    return Path()
      ..moveTo(inside.dx, inside.dy)
      ..quadraticBezierTo(control.dx, control.dy, mouth.dx, mouth.dy)
      ..cubicTo(outside.dx, outside.dy, tail.dx, tail.dy, end.dx, end.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(buildPath(), _line(PetPlanterPalette.cloth, 3.5));
  }

  @override
  bool shouldRepaint(PetStripPainter oldDelegate) =>
      frame != oldDelegate.frame || stepIndex != oldDelegate.stepIndex;
}

class PetCutGuidePainter extends CustomPainter {
  const PetCutGuidePainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    for (var x = 106.0; x < 215; x += 10) {
      canvas.drawLine(
        Offset(x, 180),
        Offset(math.min(x + 5, 215), 180),
        _line(PetPlanterPalette.cut, 2),
      );
    }
    if (progress > 0) {
      canvas.drawLine(
        const Offset(215, 180),
        Offset(215 - 110 * progress, 180),
        _line(PetPlanterPalette.cut, 2),
      );
    }
  }

  @override
  bool shouldRepaint(PetCutGuidePainter oldDelegate) =>
      progress != oldDelegate.progress;
}

class PetScissorsPainter extends CustomPainter {
  const PetScissorsPainter(this.opening);
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
      canvas.rotate(side * (.1 + .3 * opening));
      canvas.drawLine(
        const Offset(-24, 0),
        const Offset(13, 0),
        _line(PetPlanterPalette.tool, 2),
      );
      canvas.drawLine(
        const Offset(13, 0),
        Offset(18, side * 4),
        _line(PetPlanterPalette.tool, 2),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(25, side * 5), width: 15, height: 11),
        _line(PetPlanterPalette.tool, 2),
      );
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, 2, Paint()..color = PetPlanterPalette.tool);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PetScissorsPainter oldDelegate) =>
      opening != oldDelegate.opening;
}

class PetPourPainter extends CustomPainter {
  const PetPourPainter(this.frame);
  final MotionFrame frame;
  @override
  void paint(Canvas canvas, Size size) {
    if (frame.activeKind != MotionKind.pour) return;
    if (frame['soil'].amount > 0 && frame['soil'].amount < 1) {
      for (var i = 0; i < 5; i++) {
        final y = 65 + ((frame.activeProgress * 95 + i * 15) % 85);
        canvas.drawCircle(
          Offset(147 + (i % 3) * 13.0, y),
          2,
          Paint()..color = PetPlanterPalette.soil,
        );
      }
    } else if (frame['water'].amount > 0 && frame['water'].amount < 1) {
      final stream = Path()
        ..moveTo(245, 163)
        ..quadraticBezierTo(220, 160, 210, 180)
        ..lineTo(207, 274);
      canvas.drawPath(stream, _line(PetPlanterPalette.water, 2));
      final cup = Path()
        ..moveTo(256, 136)
        ..lineTo(279, 145)
        ..quadraticBezierTo(283, 147, 281, 151)
        ..lineTo(273, 171)
        ..quadraticBezierTo(271, 175, 267, 173)
        ..lineTo(245, 163);
      canvas.drawPath(cup, _line(PetPlanterPalette.tool));
    } else if (frame['moisture'].amount > 0 && frame['moisture'].amount < 1) {
      for (var i = 0; i < 3; i++) {
        final y = 105 + ((frame.activeProgress * 50 + i * 12) % 40);
        canvas.drawLine(
          Offset(135 + i * 24.0, y),
          Offset(135 + i * 24.0, y + 5),
          _line(PetPlanterPalette.water, 1.5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(PetPourPainter oldDelegate) => frame != oldDelegate.frame;
}
