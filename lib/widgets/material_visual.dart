import 'package:flutter/material.dart';

import '../models/material_item.dart';
import 'recipe_icon_grid.dart';
import 'workshop_vector_icon.dart';

/// Raw materials only; never displays a finished project's product photo.
class MaterialVisual extends StatelessWidget {
  const MaterialVisual(this.type, {super.key, this.size = 64});
  final WasteType type;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: type.label,
    child: ExcludeSemantics(
      child: switch (type) {
        WasteType.unknown => SizedBox.square(
          dimension: size,
          child: const Icon(Icons.help_outline, size: 40),
        ),
        WasteType.metal => SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: _CanPainter()),
        ),
        WasteType.plasticPackaging => WorkshopVectorIcon(
          WorkshopIconKind.bag,
          size: size,
        ),
        _ => WorkshopVectorIcon(
          RecipeVisualItem.materialIcon(type.materialId!),
          size: size,
        ),
      },
    ),
  );
}

class _CanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 80, size.height / 80);
    final line = Paint()
      ..color = const Color(0xFF203D50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(19, 17, 42, 49),
      const Radius.circular(7),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFD7E5DF));
    canvas.drawRRect(body, line);
    canvas.drawOval(
      const Rect.fromLTWH(19, 10, 42, 15),
      Paint()..color = const Color(0xFFF1F5F1),
    );
    canvas.drawOval(const Rect.fromLTWH(19, 10, 42, 15), line);
    for (final y in [35.0, 46.0, 57.0]) {
      canvas.drawLine(Offset(25, y), Offset(55, y), line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CanPainter oldDelegate) => false;
}
