import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Code-drawn editorial placeholder. It never treats image_prompt as a URL.
class WorkshopArtwork extends StatelessWidget {
  const WorkshopArtwork({
    super.key,
    this.materialId = 'cardboard_roll',
    this.hero = false,
  });
  final String materialId;
  final bool hero;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRect(
      child: CustomPaint(
        painter: _WorkshopPainter(materialId, hero),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _WorkshopPainter extends CustomPainter {
  const _WorkshopPainter(this.materialId, this.hero);
  final String materialId;
  final bool hero;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 320, size.height / 200);
    final bg = hero ? const Color(0xFFECF4E8) : const Color(0xFFF0F2EA);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 320, 200), Paint()..color = bg);
    final blob = Path()
      ..moveTo(67, 59)
      ..cubicTo(89, 7, 211, 5, 256, 51)
      ..cubicTo(301, 95, 276, 165, 205, 177)
      ..cubicTo(133, 191, 35, 137, 67, 59);
    canvas.drawPath(
      blob,
      Paint()..color = AppTheme.secondary.withValues(alpha: .28),
    );
    canvas.drawOval(
      const Rect.fromLTWH(62, 158, 203, 18),
      Paint()..color = AppTheme.primary.withValues(alpha: .07),
    );
    final line = Paint()
      ..color = AppTheme.primary.withValues(alpha: .11)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(285, 35), 42, line);
    canvas.drawCircle(const Offset(32, 175), 45, line);
    if (hero) {
      _jar(canvas, 192, 79, small: true);
      _roll(canvas, 105, 80, height: 83);
      _roll(canvas, 144, 99, height: 64);
      _leaf(canvas, const Offset(222, 70), -.4);
    } else {
      switch (materialId) {
        case 'glass_jar':
          _jar(canvas, 126, 72);
          _leaf(canvas, const Offset(160, 70), -.3);
        case 'pet_bottle':
          _bottle(canvas);
        case 'yogurt_container':
          _pot(canvas);
        case 'egg_carton':
          _carton(canvas);
        default:
          _box(canvas);
          if (materialId == 'cardboard_roll') {
            _roll(canvas, 113, 65, height: 85);
            _roll(canvas, 154, 79, height: 71);
            _roll(canvas, 195, 92, height: 58);
          } else {
            _leaf(canvas, const Offset(164, 84), .2);
          }
      }
    }
    final accent = Paint()..color = AppTheme.accent;
    canvas.drawCircle(const Offset(67, 57), 4, accent);
    canvas.drawLine(
      const Offset(265, 113),
      const Offset(277, 113),
      Paint()
        ..color = AppTheme.primary
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      const Offset(271, 107),
      const Offset(271, 119),
      Paint()
        ..color = AppTheme.primary
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  void _roll(Canvas c, double x, double y, {required double height}) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 34, height),
        const Radius.circular(5),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFD6BA94), Color(0xFFEAD6B8), Color(0xFFC9A67F)],
        ).createShader(Rect.fromLTWH(x, y, 34, height)),
    );
    c.drawOval(
      Rect.fromLTWH(x, y - 5, 34, 12),
      Paint()..color = const Color(0xFFF1E2CA),
    );
    c.drawOval(
      Rect.fromLTWH(x + 5, y - 2, 24, 6),
      Paint()..color = const Color(0xFF8C7056),
    );
    c.drawLine(
      Offset(x + 6, y + 26),
      Offset(x + 28, y + 44),
      Paint()
        ..color = const Color(0xFFC0A17F)
        ..strokeWidth = .8,
    );
  }

  void _box(Canvas c) {
    final side = Path()
      ..moveTo(84, 120)
      ..lineTo(215, 120)
      ..lineTo(243, 140)
      ..lineTo(243, 168)
      ..lineTo(99, 168)
      ..lineTo(84, 149)
      ..close();
    c.drawPath(side, Paint()..color = const Color(0xFFD6B48C));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(99, 137, 144, 31),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFE4C8A3),
    );
  }

  void _jar(Canvas c, double x, double y, {bool small = false}) {
    final w = small ? 48.0 : 68.0;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, 87),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFFD5E8DB),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, 87),
        const Radius.circular(12),
      ),
      Paint()
        ..color = AppTheme.primary.withValues(alpha: .45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 2, y - 4, w + 4, 12),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFD5B78D),
    );
    c.drawLine(
      Offset(x + 9, y + 19),
      Offset(x + 9, y + 56),
      Paint()
        ..color = Colors.white.withValues(alpha: .85)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 14, y + 37, w - 25, 27),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFFFF9EE),
    );
  }

  void _leaf(Canvas c, Offset p, double angle) {
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(angle);
    c.drawLine(
      const Offset(0, 20),
      const Offset(0, -24),
      Paint()
        ..color = AppTheme.primary
        ..strokeWidth = 2,
    );
    c.drawPath(
      Path()
        ..moveTo(0, -10)
        ..cubicTo(-29, -6, -34, -34, -26, -39)
        ..cubicTo(-6, -35, 2, -20, 0, -10),
      Paint()..color = const Color(0xFF54866A),
    );
    c.drawPath(
      Path()
        ..moveTo(0, -20)
        ..cubicTo(24, -14, 34, -42, 26, -48)
        ..cubicTo(6, -44, -1, -30, 0, -20),
      Paint()..color = AppTheme.primary,
    );
    c.restore();
  }

  void _bottle(Canvas c) {
    c.save();
    c.translate(140, 42);
    c.rotate(.12);
    final body = Path()
      ..moveTo(0, 20)
      ..lineTo(33, 20)
      ..lineTo(33, 40)
      ..cubicTo(33, 51, 48, 57, 48, 70)
      ..lineTo(48, 118)
      ..quadraticBezierTo(48, 128, 38, 128)
      ..lineTo(-5, 128)
      ..quadraticBezierTo(-15, 128, -15, 118)
      ..lineTo(-15, 70)
      ..cubicTo(-15, 57, 0, 51, 0, 40)
      ..close();
    c.drawPath(body, Paint()..color = const Color(0xFFCAE2D4));
    c.drawPath(
      body,
      Paint()
        ..color = const Color(0xFF64947A)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2, 10, 37, 15),
        const Radius.circular(4),
      ),
      Paint()..color = AppTheme.primary,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-15, 77, 63, 28),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFFF8E9),
    );
    c.restore();
    _leaf(c, const Offset(213, 135), .7);
  }

  void _pot(Canvas c) {
    c.drawPath(
      Path()
        ..moveTo(108, 95)
        ..lineTo(219, 95)
        ..lineTo(203, 164)
        ..lineTo(125, 164)
        ..close(),
      Paint()..color = const Color(0xFFFDFBF3),
    );
    c.drawOval(
      const Rect.fromLTWH(108, 84, 111, 23),
      Paint()..color = const Color(0xFFD6B48C),
    );
    c.drawOval(
      const Rect.fromLTWH(116, 88, 95, 13),
      Paint()..color = const Color(0xFF8F765C),
    );
    _leaf(c, const Offset(165, 82), .1);
    c.drawLine(
      const Offset(140, 135),
      const Offset(190, 135),
      Paint()
        ..color = AppTheme.accent
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _carton(Canvas c) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(70, 81, 181, 85),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFFCFB997),
    );
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 6; col++) {
        c.drawOval(
          Rect.fromLTWH(78 + col * 28, 91 + row * 35, 22, 25),
          Paint()..color = const Color(0xFFA38E70),
        );
        c.drawCircle(
          Offset(89 + col * 28, 102 + row * 35),
          4,
          Paint()..color = col.isEven ? AppTheme.primary : AppTheme.accent,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WorkshopPainter oldDelegate) =>
      oldDelegate.materialId != materialId || oldDelegate.hero != hero;
}
