import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/eco_guide_messages.dart';
import 'eco_mascot_avatar.dart';

export '../core/eco_guide_messages.dart' show EcoGuideScene;

/// Occupies normal document space, so it never floats over the main controls.
class EcoGuide extends StatelessWidget {
  const EcoGuide({super.key, required this.scene, this.compact = false});
  final EcoGuideScene scene;
  final bool compact;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(compact ? 8 : 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        EcoMascotAvatar(
          mood: EcoGuideMessages.mood(scene),
          size: compact ? 82 : 90,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: EcoSpeechBubble(
            message: EcoGuideMessages.text(scene),
            fontSize: compact ? 12 : 13,
          ),
        ),
      ],
    ),
  );
}

class EcoSpeechBubble extends StatelessWidget {
  const EcoSpeechBubble({
    super.key,
    required this.message,
    this.fontSize = 15,
    this.tailAbove = false,
    this.padding = 12,
  });
  final String message;
  final double fontSize;
  final bool tailAbove;
  final double padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BubbleTail(above: tailAbove),
    child: Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E5D5)),
      ),
      child: Text(
        message,
        textAlign: tailAbove ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: fontSize,
          height: 1.4,
          color: AppTheme.primary,
        ),
      ),
    ),
  );
}

class _BubbleTail extends CustomPainter {
  _BubbleTail({this.above = false});
  final bool above;
  @override
  void paint(Canvas canvas, Size size) {
    final p = above
        ? (Path()
            ..moveTo(size.width * .5 - 8, 2)
            ..lineTo(size.width * .5, -9)
            ..lineTo(size.width * .5 + 8, 2)
            ..close())
        : (Path()
            ..moveTo(2, size.height * .55)
            ..lineTo(-8, size.height * .7)
            ..lineTo(4, size.height * .7)
            ..close());
    canvas.drawPath(p, Paint()..color = const Color(0xFFFBF7E9));
  }

  @override
  bool shouldRepaint(covariant _BubbleTail oldDelegate) =>
      oldDelegate.above != above;
}
