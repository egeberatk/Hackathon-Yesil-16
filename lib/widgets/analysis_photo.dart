import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class AnalysisPhoto extends StatefulWidget {
  const AnalysisPhoto({super.key, required this.bytes, required this.active});
  final Uint8List bytes;
  final bool active;
  @override
  State<AnalysisPhoto> createState() => _AnalysisPhotoState();
}

class _AnalysisPhotoState extends State<AnalysisPhoto>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  void _updateAnimation() {
    if (widget.active && !MediaQuery.disableAnimationsOf(context)) {
      _animation.repeat(reverse: true);
    } else {
      _animation.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant AnalysisPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _updateAnimation();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: AspectRatio(
      aspectRatio: 1.15,
      child: ColoredBox(
        color: const Color(0xFFEDF1EE),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              widget.bytes,
              fit: BoxFit.contain,
              semanticLabel: 'Seçilen fotoğraf',
              errorBuilder: (_, error, stack) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Görsel biçimi önizlenemiyor. Başka bir fotoğraf seçebilirsin.',
                  ),
                ),
              ),
            ),
            if (widget.active)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) =>
                      CustomPaint(painter: _ScanPainter(_animation.value)),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _ScanPainter extends CustomPainter {
  const _ScanPainter(this.position);
  final double position;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(16, 16, size.width - 32, size.height - 32);
    final stroke = Paint()
      ..color = AppTheme.secondary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      final dx = corner.dx == rect.left ? 1 : -1;
      final dy = corner.dy == rect.top ? 1 : -1;
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx, corner.dy + dy * 22)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx + dx * 22, corner.dy),
        stroke,
      );
    }
    final y = rect.top + rect.height * position;
    final band = Rect.fromLTWH(rect.left, y - 32, rect.width, 32);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.secondary.withValues(alpha: 0),
            AppTheme.secondary.withValues(alpha: .24),
          ],
        ).createShader(band),
    );
    canvas.drawLine(
      Offset(rect.left, y),
      Offset(rect.right, y),
      stroke..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanPainter oldDelegate) =>
      oldDelegate.position != position;
}
