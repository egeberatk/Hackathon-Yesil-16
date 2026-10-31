part of 'workshop_step_scene.dart';

/// Flat vector components. Geometry changes reveal folds, joints and contents;
/// timing, looping and transforms remain in MotionSequence/RecipeMotionPlayer.
extension _Package3Parts on _ScenePainter {
  static const _ink = _ScenePainter.ink,
      _tan = _ScenePainter.tan,
      _blue = _ScenePainter.blue,
      _green = _ScenePainter.green,
      _coral = _ScenePainter.coral,
      _paper = Color(0xFFFFFCF4);

  Path _topBottle() => Path()
    ..moveTo(-15, -66)
    ..lineTo(-15, -48)
    ..cubicTo(-32, -31, -36, -24, -36, -6)
    ..lineTo(-36, 0)
    ..lineTo(36, 0)
    ..lineTo(36, -6)
    ..cubicTo(36, -24, 32, -31, 15, -48)
    ..lineTo(15, -66)
    ..close();

  Path _notchedStrip(String label, {bool closeup = false}) {
    final slots = closeup ? [0.0] : [-35.0, 35.0];
    final p = Path()..moveTo(-90, -26);
    if (label == 'top') {
      for (final x in slots) {
        p
          ..lineTo(x - 4, -26)
          ..lineTo(x - 4, 0)
          ..lineTo(x + 4, 0)
          ..lineTo(x + 4, -26);
      }
    }
    p
      ..lineTo(90, -26)
      ..lineTo(90, 26);
    if (label == 'bottom') {
      for (final x in slots.reversed) {
        p
          ..lineTo(x + 4, 26)
          ..lineTo(x + 4, 0)
          ..lineTo(x - 4, 0)
          ..lineTo(x - 4, 26);
      }
    }
    return p
      ..lineTo(-90, 26)
      ..close();
  }

  void _joint(Canvas c, double t) {
    final dy = -75 * (1 - t);
    final crossing = Path()
      ..moveTo(-46, -65 + dy)
      ..lineTo(46, 25 + dy)
      ..lineTo(46, 77 + dy)
      ..lineTo(3, 35 + dy)
      ..lineTo(3, 9 + dy)
      ..lineTo(-3, 3 + dy)
      ..lineTo(-3, 29 + dy)
      ..lineTo(-46, -13 + dy)
      ..close();
    shape(c, crossing, _tan);
    final front = Path()
      ..moveTo(-110, -20)
      ..lineTo(-4, -20)
      ..lineTo(-4, 6)
      ..lineTo(4, 6)
      ..lineTo(4, -20)
      ..lineTo(110, -20)
      ..lineTo(110, 32)
      ..lineTo(-110, 32)
      ..close();
    shape(c, front, const Color(0xFFF1DABC));
    // The near half passes in front; the far half stays behind the first strip.
    c.save();
    c.clipRect(const Rect.fromLTWH(0, -200, 140, 400));
    shape(c, crossing, _tan);
    c.restore();
  }

  void package3Object(Canvas c, WorkshopPart part, double amount) {
    switch (part.object) {
      case WorkshopObject.paperPanel:
        rect(c, const Rect.fromLTWH(-90, -37, 180, 74), _paper, 4);
      case WorkshopObject.accordion:
        final t = (amount - 1).clamp(0.0, 1.0);
        // Each crease segment retains its length as projected width shrinks.
        final span = 240 - 70 * t, dx = span / 6;
        final amplitude = math.sqrt(math.max(0, 40 * 40 - dx * dx)) / 2;
        final edge = <Offset>[
          for (var i = 0; i < 7; i++)
            Offset(-span / 2 + i * dx, i.isEven ? -amplitude : amplitude),
        ];
        final p = Path()..moveTo(edge.first.dx, edge.first.dy);
        for (final point in edge.skip(1)) {
          p.lineTo(point.dx, point.dy);
        }
        for (final point in edge.reversed) {
          p.lineTo(point.dx, point.dy + 24);
        }
        p.close();
        shape(c, p, _paper);
        for (final point in edge.skip(1).take(5)) {
          stroke(c, point.dx, point.dy, point.dx, point.dy + 24);
        }
      case WorkshopObject.receipt:
        rect(c, const Rect.fromLTWH(-14, -27, 28, 54), _paper, 3);
        for (var i = 0; i < 3; i++) {
          stroke(c, -8, -14 + i * 12, 8, -14 + i * 12);
        }
      case WorkshopObject.shallowFrame:
        rect(c, const Rect.fromLTWH(-110, -51, 220, 102), _tan, 8);
        rect(
          c,
          const Rect.fromLTWH(-94, -39, 188, 78),
          const Color(0xFFF6ECDD),
          4,
        );
      case WorkshopObject.cardboardStrip:
        rect(c, const Rect.fromLTWH(-90, -7, 180, 14), _tan, 2);
        for (var i = 0; i < (part.label == 'packed' ? 0 : 14); i++) {
          c.drawOval(
            Rect.fromLTWH(-84 + i * 12, -3, 8, 6),
            line..strokeWidth = 1.8,
          );
        }
      case WorkshopObject.slottedStrip:
        shape(c, _notchedStrip(part.label), _tan);
        if (part.label == 'marked') {
          for (final x in [-35.0, 35.0]) {
            for (var i = 0; i < 3; i++) {
              c.drawLine(
                Offset(x, -23 + i * 9),
                Offset(x, -18 + i * 9),
                line
                  ..color = _coral
                  ..strokeWidth = 3,
              );
            }
          }
        }
      case WorkshopObject.interlock:
        _joint(c, (amount - 1).clamp(0.0, 1.0));
      case WorkshopObject.drawerGrid:
        rect(c, const Rect.fromLTWH(-110, -62, 220, 124), _tan, 8);
        rect(c, const Rect.fromLTWH(-98, -50, 196, 100), _paper, 4);
        for (final x in [-34.0, 34.0]) {
          rect(c, Rect.fromLTWH(x - 3, -50, 6, 100), _tan, 1);
        }
        for (final y in [-18.0, 18.0]) {
          rect(c, Rect.fromLTWH(-98, y - 3, 196, 6), _tan, 1);
        }
      case WorkshopObject.compression:
        final x = 140 - 13 * amount.clamp(0, 1);
        for (final sign in [-1.0, 1.0]) {
          final arrow = Path()
            ..moveTo(sign * x, 0)
            ..lineTo(sign * (x + 12), -9)
            ..lineTo(sign * (x + 12), 9)
            ..close();
          shape(c, arrow, _coral);
        }
      case WorkshopObject.petTop:
        shape(c, _topBottle(), _blue.withValues(alpha: .55));
      case WorkshopObject.petBase:
        shape(
          c,
          Path()
            ..moveTo(-36, 0)
            ..lineTo(-36, 60)
            ..quadraticBezierTo(-36, 77, -18, 72)
            ..quadraticBezierTo(0, 80, 18, 72)
            ..quadraticBezierTo(36, 77, 36, 60)
            ..lineTo(36, 0)
            ..close(),
          _blue.withValues(alpha: .55),
        );
        for (final y in [26.0, 52.0]) {
          stroke(c, -31, y, 31, y);
        }
      case WorkshopObject.cutMark:
        for (var i = 0; i < 6 * amount.clamp(0, 1); i++) {
          c.drawLine(
            Offset(-36 + i * 12, 0),
            Offset(-29 + i * 12, 0),
            line
              ..color = _coral
              ..strokeWidth = 4,
          );
        }
      case WorkshopObject.sideCap:
        rect(
          c,
          const Rect.fromLTWH(-19, -8, 38, 16),
          const Color(0xFF86B7D2),
          4,
        );
        stroke(c, -14, 1, 14, 1);
      case WorkshopObject.bagBody:
        shape(
          c,
          Path()
            ..moveTo(-50, -32)
            ..lineTo(50, -32)
            ..lineTo(61, 60)
            ..quadraticBezierTo(0, 68, -61, 60)
            ..close(),
          const Color(0xFFFFF3D5),
        );
        stroke(c, -45, -24, 45, -24);
      case WorkshopObject.bagMouth:
        final thread = (amount - 1).clamp(0.0, 1.0),
            fold = (amount - 2).clamp(0.0, 1.0);
        final tip = 60 - 148 * thread + 22 * fold;
        shape(
          c,
          Path()
            ..moveTo(-48, 70)
            ..quadraticBezierTo(-12, 40, -8, tip)
            ..lineTo(8, tip)
            ..quadraticBezierTo(12, 40, 48, 70)
            ..close(),
          const Color(0xFFFFF3D5),
        );
        if (fold > 0) {
          for (final sign in [-1.0, 1.0]) {
            shape(
              c,
              Path()
                ..moveTo(sign * 8, -88 + 22 * fold)
                ..lineTo(sign * (8 + 18 * fold), -88 + 25 * fold)
                ..lineTo(sign * (4 + 13 * fold), -80 + 25 * fold)
                ..lineTo(sign * 3, -80 + 14 * fold)
                ..close(),
              const Color(0xFFFFE7AB),
            );
          }
        }
      case WorkshopObject.dryStream:
        for (var i = 0; i < 8; i++) {
          final start = i * .085;
          final t = ((amount - start) / (1 - start)).clamp(0.0, 1.0);
          if (t > 0 && t < 1) {
            c.drawCircle(
              Offset(i.isEven ? -2.5 : 2.5, -55 + 157 * t),
              3.2,
              Paint()..color = _tan,
            );
          }
        }
      case WorkshopObject.dryPile:
        c.save();
        c.clipPath(Path()..addOval(const Rect.fromLTWH(-37, -12, 74, 17)));
        for (var i = 0; i < (18 * amount.clamp(0, 1)).round(); i++) {
          c.drawCircle(
            Offset(-20 + i % 6 * 8, -8 + i ~/ 6 * 7),
            3.5,
            Paint()..color = _tan,
          );
        }
        c.restore();
      case WorkshopObject.ventHoles:
        if (part.label == 'top') {
          ellipse(c, const Rect.fromLTWH(-58, -58, 116, 116), _green);
          for (var i = 0; i < 3; i++) {
            final a = -math.pi / 2 + i * math.pi * 2 / 3;
            ellipse(
              c,
              Rect.fromCircle(
                center: Offset(math.cos(a) * 42, math.sin(a) * 42),
                radius: 7,
              ),
              _paper,
            );
          }
        } else {
          for (var i = 0; i < (15 * amount.clamp(0, 1)).round(); i++) {
            c.drawCircle(
              Offset(-34 + i % 5 * 17, -2 + i ~/ 5 * 17),
              2.6,
              Paint()..color = _ink,
            );
          }
          for (final p in [
            const Offset(-44, -27),
            const Offset(44, -27),
            const Offset(0, -16),
          ]) {
            ellipse(c, Rect.fromCircle(center: p, radius: 3.5), _paper);
          }
        }
      case WorkshopObject.suspensionRope:
        final i = int.parse(part.label), join = (amount - 1).clamp(0.0, 1.0);
        final bottom = [
          const Offset(-55, 110),
          const Offset(55, 110),
          const Offset(0, 126),
        ][i];
        final free = [
          const Offset(-65, 0),
          const Offset(65, 0),
          const Offset(0, -20),
        ][i];
        final top = Offset.lerp(free, const Offset(0, -30), join)!;
        final slack = [
          const Offset(-140, 10),
          const Offset(140, 10),
          const Offset(40, 40),
        ][i];
        final control = Offset.lerp(slack, (bottom + top) / 2, join)!;
        reveal(
          c,
          Path()
            ..moveTo(bottom.dx, bottom.dy)
            ..quadraticBezierTo(control.dx, control.dy, top.dx, top.dy),
          amount.clamp(0, 1),
        );
        ellipse(c, Rect.fromCircle(center: bottom, radius: 4.5), _tan);
      case WorkshopObject.hangerRing:
        c.drawCircle(Offset.zero, 10, line);
        stroke(c, 0, -10, 0, -25);
      case WorkshopObject.onion:
        shape(
          c,
          Path()
            ..moveTo(-3, -25)
            ..cubicTo(-9, -7, -26, -7, -26, 12)
            ..cubicTo(-26, 37, 26, 37, 26, 12)
            ..cubicTo(26, -7, 9, -7, 3, -25)
            ..close(),
          _tan,
        );
        stroke(c, 0, -32, 0, -18);
      case WorkshopObject.liquidFill:
        final h = (40 * amount.clamp(0, 1)).toDouble();
        rect(c, Rect.fromLTWH(-57, 76 - h, 114, h), const Color(0xFFE8BE7A), 4);
      case WorkshopObject.pourStream:
        final path = Path()
          ..moveTo(-32, -4)
          ..cubicTo(-20, -2, 0, 12, 0, 40)
          ..lineTo(0, 175);
        for (final metric in path.computeMetrics()) {
          c.drawPath(
            metric.extractPath(0, metric.length * amount.clamp(0, 1)),
            line
              ..color = const Color(0xFFD4A762)
              ..strokeWidth = 5,
          );
        }
      case WorkshopObject.ingredientBottle:
        rect(
          c,
          const Rect.fromLTWH(-23, -25, 46, 66),
          const Color(0xFFF1D385),
          6,
        );
        rect(c, const Rect.fromLTWH(-9, -50, 18, 26), _tan, 3);
      case WorkshopObject.singleDrop:
        shape(
          c,
          Path()
            ..moveTo(0, -12)
            ..quadraticBezierTo(-17, 12, 0, 14)
            ..quadraticBezierTo(17, 12, 0, -12)
            ..close(),
          _green,
        );
      case WorkshopObject.paperCone:
        final t = (amount - 1).clamp(0.0, 1.0), tip = 75 - 70 * t;
        shape(
          c,
          Path()
            ..moveTo(-75, -50)
            ..lineTo(75, -50)
            ..lineTo(tip, 60 + 10 * t)
            ..lineTo(-tip, 60 + 10 * t)
            ..close(),
          _paper,
        );
        stroke(c, 40, -20, tip, 60 + 10 * t);
      default:
        break;
    }
  }
}
