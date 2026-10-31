part of 'workshop_step_scene.dart';

/// New sprites share the existing outline, palette and transformation pipeline.
extension _Package2Parts on _ScenePainter {
  static const _ink = _ScenePainter.ink,
      _tan = _ScenePainter.tan,
      _blue = _ScenePainter.blue,
      _green = _ScenePainter.green,
      _coral = _ScenePainter.coral;
  static const _colors = [
    _coral,
    _blue,
    _green,
    Color(0xFFF1D385),
    Color(0xFFC7B5DC),
  ];
  Color _pairColor(String label) =>
      _colors[(int.tryParse(label) ?? 0) % _colors.length];
  void package2Object(Canvas c, WorkshopPart part, double amount) {
    switch (part.object) {
      case WorkshopObject.sheet:
        rect(
          c,
          const Rect.fromLTWH(-42, -34, 84, 68),
          part.label == 'mat' ? _tan : const Color(0xFFFFFCF4),
          4,
        );
        if (part.label == 'writing') {
          for (var i = 0; i < 3; i++) {
            reveal(
              c,
              Path()
                ..moveTo(-27, -17 + i * 17)
                ..lineTo(i == 2 ? 10 : 27, -17 + i * 17),
              amount,
            );
          }
        }
      case WorkshopObject.foldingPaper:
        final fold = (amount - 1).clamp(0.0, 1.0);
        rect(
          c,
          Rect.fromLTWH(-35, -28, 70 - 35 * fold, 56),
          const Color(0xFFFFF7DE),
          4,
        );
        stroke(c, 0, -26, 0, 26);
        shape(
          c,
          Path()
            ..moveTo(35 - 35 * fold, -28)
            ..lineTo(35 - 35 * fold, 28)
            ..lineTo(35 - 55 * fold, 28 - 12 * fold)
            ..lineTo(35 - 55 * fold, -28 + 12 * fold)
            ..close(),
          const Color(0xFFF4DDAA),
        );
      case WorkshopObject.foldingFlap:
        final fold = (amount - 1).clamp(0.0, 1.0);
        shape(
          c,
          Path()
            ..moveTo(-102, 0)
            ..lineTo(102, 0)
            ..lineTo(85, (-43 + 78 * fold))
            ..lineTo(-85, (-43 + 78 * fold))
            ..close(),
          _tan,
        );
        stroke(c, -102, 0, 102, 0);
      case WorkshopObject.cable:
        final loosen = (amount - 1).clamp(0.0, 1.0);
        final path = Path()
          ..moveTo(-55, 34)
          ..cubicTo(-10, 56, 65, 34, 35, -12)
          ..cubicTo(10, -50, -55, -25, -20, 15)
          ..cubicTo(10, 48, 65, -8, 30 + 30 * loosen, -30 - 35 * loosen);
        c.drawPath(
          path,
          Paint()
            ..color = _ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..strokeCap = StrokeCap.round,
        );
        c.drawPath(
          path,
          Paint()
            ..color = _blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
        rect(
          c,
          Rect.fromLTWH(21 + 30 * loosen, -48 - 35 * loosen, 18, 22),
          _blue,
          3,
        );
        rect(c, const Rect.fromLTWH(-65, 26, 18, 16), _tan, 3);
      case WorkshopObject.frameWrap:
        if (part.label == 'pattern') {
          for (var i = 0; i < 4; i++) {
            reveal(
              c,
              Path()
                ..moveTo(-76 + i * 48, -78)
                ..lineTo(-64 + i * 48, -68)
                ..lineTo(-52 + i * 48, -78),
              amount,
            );
          }
          for (var i = 0; i < 4; i++) {
            reveal(
              c,
              Path()
                ..moveTo(-76 + i * 48, 78)
                ..lineTo(-64 + i * 48, 68)
                ..lineTo(-52 + i * 48, 78),
              amount,
            );
          }
        } else {
          final extra = 18 * (1 - (amount - 1).clamp(0.0, 1.0));
          rect(
            c,
            Rect.fromLTRB(-100 - extra, -100 - extra, 100 + extra, 100 + extra),
            const Color(0xFFFFFCF4),
            5,
          );
          c.drawRect(
            const Rect.fromLTRB(-100, -100, 100, 100),
            line..strokeWidth = 2,
          );
        }
      case WorkshopObject.photo:
        rect(c, const Rect.fromLTWH(-68, -46, 136, 92), _blue, 4);
        c.drawCircle(
          const Offset(38, -21),
          11,
          Paint()..color = const Color(0xFFF1D385),
        );
        shape(
          c,
          Path()
            ..moveTo(-64, 41)
            ..lineTo(-20, -9)
            ..lineTo(9, 20)
            ..lineTo(32, 0)
            ..lineTo(64, 41)
            ..close(),
          _green,
        );
      case WorkshopObject.jar:
        final path = Path()
          ..moveTo(-39, -94)
          ..lineTo(39, -94)
          ..lineTo(39, -75)
          ..quadraticBezierTo(66, -66, 66, -43)
          ..lineTo(66, 70)
          ..quadraticBezierTo(66, 88, 45, 88)
          ..lineTo(-45, 88)
          ..quadraticBezierTo(-66, 88, -66, 70)
          ..lineTo(-66, -43)
          ..quadraticBezierTo(-66, -66, -39, -75)
          ..close();
        shape(c, path, _blue.withValues(alpha: .22));
        rect(
          c,
          const Rect.fromLTWH(-43, -101, 86, 14),
          _blue.withValues(alpha: .45),
          4,
        );
      case WorkshopObject.paperDot:
        ellipse(
          c,
          const Rect.fromLTWH(-18, -18, 36, 36),
          part.label == 'plain'
              ? const Color(0xFFFFFCF4)
              : Color.lerp(
                  const Color(0xFFFFFCF4),
                  _pairColor(part.label),
                  amount.clamp(0, 1),
                )!,
        );
      case WorkshopObject.flipCap:
        // amount 1 = coloured inside; 2 = hidden reverse. Rotate about Y
        // through a narrow silhouette, rather than spinning a face in the plane.
        final flip = (amount - 1).clamp(0.0, 1.0);
        c.scale(math.cos(math.pi * flip).abs().clamp(.04, 1.0), 1);
        ellipse(c, const Rect.fromLTWH(-25, -25, 50, 50), _blue);
        if (flip < .5) {
          ellipse(
            c,
            const Rect.fromLTWH(-18, -18, 36, 36),
            _pairColor(part.label),
          );
        } else {
          c.drawOval(
            const Rect.fromLTWH(-17, -17, 34, 34),
            line..strokeWidth = 2.5,
          );
        }
      case WorkshopObject.binocularWrap:
        final width = 122 * amount.clamp(0.02, 1.0);
        rect(c, Rect.fromLTWH(-61, -36, width, 76), _green, 6);
        stroke(c, 0, -36, 0, 40);
        if (part.label == 'pattern') {
          for (final x in [-42.0, -22.0, 20.0, 42.0]) {
            c.drawCircle(
              Offset(x, x.isNegative ? -10 : 15),
              6,
              Paint()..color = _coral,
            );
          }
        }
      case WorkshopObject.eggTray:
        rect(c, const Rect.fromLTWH(-111, -55, 222, 117), _tan, 16);
        for (var i = 0; i < 12; i++) {
          ellipse(
            c,
            Rect.fromCenter(
              center: Offset(-85 + i % 6 * 34, -30 + i ~/ 6 * 55),
              width: 29,
              height: 36,
            ),
            const Color(0xFFF5E7D3),
          );
        }
      case WorkshopObject.stone:
        final r = const Rect.fromLTWH(-3.8, -5.1, 7.6, 10.2);
        c.drawOval(r, Paint()..color = _coral);
        c.drawOval(r, line..strokeWidth = 1.5);
      case WorkshopObject.lid:
        ellipse(c, const Rect.fromLTWH(-57, -13, 114, 26), _green);
      case WorkshopObject.slot:
        if (part.label == 'guide') {
          for (var i = 0; i < 6; i++) {
            stroke(c, -27 + i * 9, -2, -22 + i * 9, -2);
          }
        } else {
          if (part.label == 'protected') {
            rect(
              c,
              const Rect.fromLTWH(-35, -9, 70, 18),
              const Color(0xFFF3D987),
              5,
            );
          }
          rect(
            c,
            Rect.fromLTWH(-28, -3, 56 * amount.clamp(.02, 1.0), 6),
            _ink,
            2,
          );
        }
      case WorkshopObject.coin:
        ellipse(
          c,
          const Rect.fromLTWH(-17, -22, 34, 44),
          const Color(0xFFF1D385),
        );
        c.drawOval(
          const Rect.fromLTWH(-11, -15, 22, 30),
          line..strokeWidth = 2,
        );
      default:
        // Other sprites are handled unchanged by the original painter.
        break;
    }
  }
}
