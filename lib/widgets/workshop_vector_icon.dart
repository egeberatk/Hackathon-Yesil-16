import 'package:flutter/material.dart';

import '../animations/motion_sequence.dart';
import '../animations/workshop_steps.dart';
import 'workshop_step_scene.dart';

enum WorkshopIconKind {
  petBottle,
  jar,
  box,
  yogurt,
  eggCarton,
  roll,
  paper,
  cap,
  scissors,
  tape,
  glue,
  pencil,
  ruler,
  cord,
  water,
  soil,
  plant,
  mat,
  drill,
  cloth,
  planter,
  other,
  ball,
  yarn,
  cable,
  photo,
  stone,
  coin,
  bag,
  hook,
  onion,
  soap,
  vinegar,
  knife,
  label,
  paperCup,
}

/// Shared, code-drawn icons. These do not depend on the construction animation.
class WorkshopVectorIcon extends StatelessWidget {
  const WorkshopVectorIcon(this.kind, {super.key, this.size = 56});
  final WorkshopIconKind kind;
  final double size;
  @override
  Widget build(BuildContext context) {
    final sprite = switch (kind) {
      WorkshopIconKind.ball => (WorkshopObject.ball, 4.0),
      WorkshopIconKind.yarn => (WorkshopObject.yarn, 2.8),
      WorkshopIconKind.cable => (WorkshopObject.cable, 1.8),
      WorkshopIconKind.photo => (WorkshopObject.photo, 1.6),
      WorkshopIconKind.stone => (WorkshopObject.stone, 18.0),
      WorkshopIconKind.coin => (WorkshopObject.coin, 4.5),
      WorkshopIconKind.paperCup => (WorkshopObject.paperCup, 2.15),
      _ => null,
    };
    if (sprite != null) {
      final step = WorkshopStep(
        description: '',
        parts: [
          WorkshopPart(
            'icon',
            sprite.$1,
            const Offset(160, 165),
            scale: sprite.$2,
          ),
        ],
        sequence: const MotionSequence(
          initial: {'icon': MotionPose(amount: 1)},
          clips: [],
        ),
      );
      return ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: WorkshopStepScene(step: step, frame: step.sequence.sample(1)),
        ),
      );
    }
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _WorkshopIconPainter(kind)),
      ),
    );
  }
}

class _WorkshopIconPainter extends CustomPainter {
  const _WorkshopIconPainter(this.kind);
  final WorkshopIconKind kind;
  static const ink = Color(0xFF203D50);
  static const blue = Color(0xFFC7E9F4);
  static const green = Color(0xFF95D5B2);
  static const tan = Color(0xFFE1C6A4);
  static const coral = Color(0xFFE9A28E);
  Paint get line => Paint()
    ..color = ink
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  void shape(Canvas c, Path p, Color colour) {
    c.drawPath(p, Paint()..color = colour);
    c.drawPath(p, line);
  }

  void rect(Canvas c, Rect r, Color colour, [double radius = 5]) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, Paint()..color = colour);
    c.drawRRect(rr, line);
  }

  void ellipse(Canvas c, Rect r, Color colour) {
    c.drawOval(r, Paint()..color = colour);
    c.drawOval(r, line);
  }

  void stroke(Canvas c, Offset a, Offset b) => c.drawLine(a, b, line);
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 80, size.height / 80);
    switch (kind) {
      case WorkshopIconKind.petBottle:
        shape(
          c,
          Path()
            ..moveTo(31, 15)
            ..lineTo(31, 22)
            ..cubicTo(22, 30, 21, 34, 21, 41)
            ..lineTo(21, 65)
            ..quadraticBezierTo(21, 73, 29, 72)
            ..quadraticBezierTo(34, 76, 40, 72)
            ..quadraticBezierTo(46, 76, 51, 72)
            ..quadraticBezierTo(59, 73, 59, 65)
            ..lineTo(59, 41)
            ..cubicTo(59, 34, 58, 30, 49, 22)
            ..lineTo(49, 15)
            ..close(),
          blue,
        );
        rect(c, const Rect.fromLTWH(29, 7, 22, 10), const Color(0xFF85B9D5), 3);
        stroke(c, const Offset(24, 43), const Offset(56, 43));
        stroke(c, const Offset(24, 55), const Offset(56, 55));
        stroke(c, const Offset(24, 65), const Offset(56, 65));
      case WorkshopIconKind.jar:
        rect(c, const Rect.fromLTWH(17, 21, 46, 49), blue, 10);
        rect(c, const Rect.fromLTWH(16, 11, 48, 12), tan, 4);
      case WorkshopIconKind.box:
        shape(
          c,
          Path()
            ..moveTo(15, 31)
            ..lineTo(65, 31)
            ..lineTo(65, 67)
            ..lineTo(15, 67)
            ..close(),
          tan,
        );
        shape(
          c,
          Path()
            ..moveTo(15, 31)
            ..lineTo(7, 17)
            ..lineTo(32, 17)
            ..lineTo(40, 31)
            ..close(),
          const Color(0xFFF0DEBE),
        );
        shape(
          c,
          Path()
            ..moveTo(40, 31)
            ..lineTo(48, 17)
            ..lineTo(73, 17)
            ..lineTo(65, 31)
            ..close(),
          const Color(0xFFF0DEBE),
        );
      case WorkshopIconKind.yogurt:
        shape(
          c,
          Path()
            ..moveTo(15, 24)
            ..lineTo(22, 66)
            ..quadraticBezierTo(40, 73, 58, 66)
            ..lineTo(65, 24)
            ..close(),
          const Color(0xFFFFF9EE),
        );
        ellipse(c, const Rect.fromLTWH(13, 16, 54, 15), blue);
      case WorkshopIconKind.eggCarton:
        rect(c, const Rect.fromLTWH(7, 16, 66, 49), tan, 8);
        for (var row = 0; row < 2; row++) {
          for (var col = 0; col < 6; col++) {
            ellipse(
              c,
              Rect.fromLTWH(12 + col * 10.0, 23 + row * 19.0, 7, 13),
              const Color(0xFFF5E6CF),
            );
          }
        }
      case WorkshopIconKind.roll:
        rect(c, const Rect.fromLTWH(23, 17, 34, 52), tan, 5);
        ellipse(
          c,
          const Rect.fromLTWH(23, 10, 34, 17),
          const Color(0xFFF5E6CF),
        );
        ellipse(c, const Rect.fromLTWH(31, 15, 18, 7), const Color(0xFFB89977));
      case WorkshopIconKind.paper:
        shape(
          c,
          Path()
            ..moveTo(20, 9)
            ..lineTo(49, 9)
            ..lineTo(62, 23)
            ..lineTo(62, 71)
            ..lineTo(20, 71)
            ..close(),
          const Color(0xFFFFFCF5),
        );
        stroke(c, const Offset(49, 9), const Offset(49, 24));
        stroke(c, const Offset(49, 24), const Offset(62, 24));
      case WorkshopIconKind.cap:
        ellipse(c, const Rect.fromLTWH(15, 15, 50, 50), coral);
        ellipse(
          c,
          const Rect.fromLTWH(25, 25, 30, 30),
          const Color(0xFFFFD4C4),
        );
      case WorkshopIconKind.scissors:
        shape(
          c,
          Path()
            ..moveTo(16, 10)
            ..lineTo(47, 43)
            ..lineTo(37, 46)
            ..close(),
          const Color(0xFFE1E8EA),
        );
        shape(
          c,
          Path()
            ..moveTo(64, 10)
            ..lineTo(33, 43)
            ..lineTo(43, 46)
            ..close(),
          const Color(0xFFE1E8EA),
        );
        stroke(c, const Offset(40, 40), const Offset(26, 58));
        stroke(c, const Offset(40, 40), const Offset(54, 58));
        ellipse(c, const Rect.fromLTWH(10, 51, 24, 21), coral);
        ellipse(c, const Rect.fromLTWH(46, 51, 24, 21), coral);
        ellipse(c, const Rect.fromLTWH(17, 57, 10, 9), Colors.white);
        ellipse(c, const Rect.fromLTWH(53, 57, 10, 9), Colors.white);
        c.drawCircle(const Offset(40, 40), 3, Paint()..color = ink);
      case WorkshopIconKind.tape:
        shape(
          c,
          Path()
            ..moveTo(52, 38)
            ..lineTo(71, 53)
            ..lineTo(61, 67)
            ..lineTo(43, 51)
            ..close(),
          tan,
        );
        ellipse(c, const Rect.fromLTWH(10, 13, 50, 50), tan);
        ellipse(c, const Rect.fromLTWH(24, 27, 22, 22), Colors.white);
      case WorkshopIconKind.glue:
        rect(c, const Rect.fromLTWH(22, 29, 36, 42), const Color(0xFFFFF9EE));
        shape(
          c,
          Path()
            ..moveTo(31, 29)
            ..lineTo(34, 9)
            ..lineTo(46, 9)
            ..lineTo(49, 29)
            ..close(),
          coral,
        );
        rect(c, const Rect.fromLTWH(29, 44, 22, 15), green, 3);
      case WorkshopIconKind.pencil:
        c.translate(40, 40);
        c.rotate(.6);
        c.translate(-40, -40);
        rect(
          c,
          const Rect.fromLTWH(32, 15, 16, 44),
          const Color(0xFFF1C875),
          2,
        );
        rect(c, const Rect.fromLTWH(32, 8, 16, 11), coral, 3);
        shape(
          c,
          Path()
            ..moveTo(32, 59)
            ..lineTo(48, 59)
            ..lineTo(40, 73)
            ..close(),
          tan,
        );
      case WorkshopIconKind.ruler:
        c.translate(40, 40);
        c.rotate(.45);
        c.translate(-40, -40);
        rect(c, const Rect.fromLTWH(26, 7, 28, 66), tan, 3);
        for (var y = 17.0; y < 70; y += 10) {
          stroke(c, Offset(27, y), Offset(38, y));
        }
      case WorkshopIconKind.cord:
        rect(
          c,
          const Rect.fromLTWH(24, 18, 32, 41),
          const Color(0xFFF4E4C9),
          5,
        );
        stroke(c, const Offset(19, 17), const Offset(61, 17));
        stroke(c, const Offset(19, 60), const Offset(61, 60));
        for (var y = 28.0; y < 56; y += 9) {
          stroke(c, Offset(27, y), Offset(53, y));
        }
        c.drawPath(
          Path()
            ..moveTo(55, 43)
            ..quadraticBezierTo(72, 42, 65, 67),
          line,
        );
      case WorkshopIconKind.water:
        shape(
          c,
          Path()
            ..moveTo(40, 8)
            ..cubicTo(33, 23, 16, 38, 18, 51)
            ..cubicTo(20, 78, 60, 78, 62, 51)
            ..cubicTo(64, 38, 47, 23, 40, 8)
            ..close(),
          blue,
        );
      case WorkshopIconKind.soil:
        shape(
          c,
          Path()
            ..moveTo(12, 64)
            ..lineTo(24, 38)
            ..lineTo(38, 31)
            ..lineTo(48, 38)
            ..lineTo(59, 43)
            ..lineTo(68, 64)
            ..close(),
          const Color(0xFFB28D6B),
        );
      case WorkshopIconKind.plant:
        stroke(c, const Offset(40, 67), const Offset(40, 18));
        shape(
          c,
          Path()
            ..moveTo(40, 42)
            ..quadraticBezierTo(14, 43, 15, 19)
            ..quadraticBezierTo(37, 17, 40, 42)
            ..close(),
          green,
        );
        shape(
          c,
          Path()
            ..moveTo(40, 31)
            ..quadraticBezierTo(42, 9, 66, 10)
            ..quadraticBezierTo(65, 33, 40, 31)
            ..close(),
          green,
        );
      case WorkshopIconKind.mat:
        rect(c, const Rect.fromLTWH(9, 15, 62, 50), green, 4);
        for (var x = 23.0; x < 67; x += 13) {
          stroke(c, Offset(x, 20), Offset(x, 60));
        }
        stroke(c, const Offset(14, 32), const Offset(66, 32));
        stroke(c, const Offset(14, 48), const Offset(66, 48));
      case WorkshopIconKind.drill:
        rect(c, const Rect.fromLTWH(19, 21, 37, 22), green, 5);
        shape(
          c,
          Path()
            ..moveTo(23, 42)
            ..lineTo(42, 42)
            ..lineTo(37, 66)
            ..lineTo(21, 66)
            ..close(),
          green,
        );
        stroke(c, const Offset(56, 31), const Offset(73, 31));
        stroke(c, const Offset(12, 14), const Offset(12, 39));
        stroke(c, const Offset(12, 26), const Offset(19, 26));
      case WorkshopIconKind.cloth:
        shape(
          c,
          Path()
            ..moveTo(19, 14)
            ..quadraticBezierTo(40, 5, 62, 16)
            ..lineTo(58, 65)
            ..quadraticBezierTo(37, 56, 16, 67)
            ..close(),
          const Color(0xFFF2DBAF),
        );
      case WorkshopIconKind.planter:
        rect(c, const Rect.fromLTWH(20, 37, 40, 37), blue, 7);
        rect(c, const Rect.fromLTWH(22, 62, 36, 9), const Color(0xFF91CADE), 2);
        shape(
          c,
          Path()
            ..moveTo(19, 30)
            ..lineTo(61, 30)
            ..lineTo(55, 46)
            ..lineTo(46, 54)
            ..lineTo(46, 59)
            ..lineTo(34, 59)
            ..lineTo(34, 54)
            ..lineTo(25, 46)
            ..close(),
          blue,
        );
        shape(
          c,
          Path()
            ..moveTo(23, 36)
            ..lineTo(57, 36)
            ..lineTo(53, 45)
            ..lineTo(45, 50)
            ..lineTo(35, 50)
            ..lineTo(27, 45)
            ..close(),
          const Color(0xFFB28D6B),
        );
        c.drawLine(
          const Offset(40, 44),
          const Offset(40, 68),
          Paint()
            ..color = const Color(0xFFE2C995)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
        stroke(c, const Offset(40, 36), const Offset(40, 13));
        shape(
          c,
          Path()
            ..moveTo(40, 27)
            ..quadraticBezierTo(17, 27, 21, 12)
            ..quadraticBezierTo(38, 12, 40, 27)
            ..close(),
          green,
        );
        shape(
          c,
          Path()
            ..moveTo(40, 19)
            ..quadraticBezierTo(43, 4, 61, 7)
            ..quadraticBezierTo(58, 24, 40, 19)
            ..close(),
          const Color(0xFF69AE80),
        );
      case WorkshopIconKind.other:
        rect(
          c,
          const Rect.fromLTWH(15, 15, 50, 50),
          const Color(0xFFEAF4ED),
          12,
        );
        stroke(c, const Offset(28, 40), const Offset(52, 40));
        stroke(c, const Offset(40, 28), const Offset(40, 52));
      case WorkshopIconKind.bag:
        shape(
          c,
          Path()
            ..moveTo(21, 20)
            ..lineTo(59, 20)
            ..lineTo(64, 70)
            ..lineTo(16, 70)
            ..close(),
          blue,
        );
        stroke(c, const Offset(22, 29), const Offset(58, 29));
      case WorkshopIconKind.hook:
        c.drawPath(
          Path()
            ..moveTo(40, 12)
            ..lineTo(40, 43)
            ..cubicTo(40, 65, 62, 62, 60, 45),
          line,
        );
        ellipse(c, const Rect.fromLTWH(33, 8, 14, 12), green);
      case WorkshopIconKind.onion:
        shape(
          c,
          Path()
            ..moveTo(37, 18)
            ..cubicTo(30, 38, 16, 35, 16, 54)
            ..cubicTo(16, 77, 64, 77, 64, 54)
            ..cubicTo(64, 35, 50, 38, 43, 18)
            ..close(),
          tan,
        );
        stroke(c, const Offset(40, 10), const Offset(40, 25));
      case WorkshopIconKind.soap:
        rect(c, const Rect.fromLTWH(22, 31, 36, 41), green);
        rect(c, const Rect.fromLTWH(30, 21, 20, 10), blue, 2);
        stroke(c, const Offset(40, 21), const Offset(40, 11));
        stroke(c, const Offset(32, 11), const Offset(60, 11));
      case WorkshopIconKind.vinegar:
        rect(c, const Rect.fromLTWH(23, 29, 34, 43), const Color(0xFFF1D385));
        rect(c, const Rect.fromLTWH(32, 12, 16, 18), tan, 3);
        ellipse(c, const Rect.fromLTWH(32, 44, 16, 16), coral);
      case WorkshopIconKind.knife:
        shape(
          c,
          Path()
            ..moveTo(22, 48)
            ..lineTo(53, 14)
            ..lineTo(63, 24)
            ..lineTo(35, 56)
            ..close(),
          blue,
        );
        rect(c, const Rect.fromLTWH(16, 48, 20, 23), tan, 5);
      case WorkshopIconKind.label:
        shape(
          c,
          Path()
            ..moveTo(17, 20)
            ..lineTo(52, 20)
            ..lineTo(65, 39)
            ..lineTo(52, 60)
            ..lineTo(17, 60)
            ..close(),
          const Color(0xFFF1D385),
        );
        stroke(c, const Offset(26, 32), const Offset(45, 32));
        stroke(c, const Offset(26, 45), const Offset(41, 45));
      case WorkshopIconKind.ball:
      case WorkshopIconKind.yarn:
      case WorkshopIconKind.cable:
      case WorkshopIconKind.photo:
      case WorkshopIconKind.stone:
      case WorkshopIconKind.coin:
      case WorkshopIconKind.paperCup:
        break; // Drawn with the existing workshop sprites above.
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_WorkshopIconPainter oldDelegate) =>
      kind != oldDelegate.kind;
}
