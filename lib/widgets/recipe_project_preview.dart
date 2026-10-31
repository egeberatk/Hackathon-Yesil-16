import 'package:flutter/material.dart';

import '../animations/motion_sequence.dart';
import '../animations/workshop_steps.dart';
import '../models/upcycling_project.dart';
import 'workshop_step_scene.dart';
import 'workshop_vector_icon.dart';

/// A stationary view of existing artwork; never owns a player/controller.
class RecipeProjectPreview extends StatelessWidget {
  const RecipeProjectPreview({super.key, required this.project});
  final UpcyclingProject project;
  static const staticIds = {
    'project_41',
    'project_42',
    'project_43',
    'project_45',
    'project_46',
    'project_47',
  };
  static const _viewports = <String, Rect>{
    'project_01': Rect.fromLTWH(30, 105, 260, 185),
    'project_15': Rect.fromLTWH(65, 30, 215, 270),
    'project_19': Rect.fromLTWH(20, 80, 280, 180),
    'project_26': Rect.fromLTWH(85, 105, 150, 155),
    'project_38': Rect.fromLTWH(75, 125, 220, 180),
    'project_39': Rect.fromLTWH(75, 25, 170, 280),
    'project_41': Rect.fromLTWH(90, 85, 140, 205),
    'project_42': Rect.fromLTWH(80, 85, 160, 230),
    'project_43': Rect.fromLTWH(60, 10, 200, 305),
    'project_44': Rect.fromLTWH(75, 140, 200, 180),
    'project_45': Rect.fromLTWH(35, 130, 250, 160),
    'project_46': Rect.fromLTWH(35, 130, 250, 160),
    'project_48': Rect.fromLTWH(0, 110, 320, 150),
  };
  @override
  Widget build(BuildContext context) {
    if (project.id == 'project_40') {
      return const Center(
        child: WorkshopVectorIcon(WorkshopIconKind.planter, size: 145),
      );
    }
    final registered = WorkshopSteps.recipes[project.id];
    // Retain the approved static overview art when these guides gain playback.
    if (registered != null &&
        !staticIds.contains(project.id) &&
        WorkshopSteps.supports(project)) {
      final index =
          {'project_15': 2, 'project_48': 2, 'project_44': 4}[project.id] ??
          registered.length - 1;
      final source = registered[index];
      final extra = <WorkshopPart>[
        if (project.id == 'project_15')
          const WorkshopPart(
            'preview-ball',
            WorkshopObject.ball,
            Offset(252, 260),
            scale: .75,
          ),
        if (project.id == 'project_44')
          const WorkshopPart(
            'preview-coin',
            WorkshopObject.coin,
            Offset(248, 233),
            scale: .85,
          ),
      ];
      final step = WorkshopStep(
        description: project.name,
        parts: [...source.parts, ...extra],
        sequence: source.sequence,
      );
      final frame = MotionFrame({
        ...source.sequence.sample(1).poses,
        for (final p in extra) p.id: const MotionPose(amount: 1),
      });
      return _SceneCrop(
        viewport:
            _viewports[project.id] ?? const Rect.fromLTWH(20, 50, 280, 265),
        child: WorkshopStepScene(step: step, frame: frame),
      );
    }
    final parts = <WorkshopPart>[
      if ({'project_45', 'project_46'}.contains(project.id))
        const WorkshopPart(
          'box',
          WorkshopObject.box,
          Offset(160, 210),
          scale: 1.1,
        ),
      if (project.id == 'project_42')
        const WorkshopPart(
          'receiver',
          WorkshopObject.cup,
          Offset(160, 263),
          scale: .8,
        ),
      if (project.id == 'project_43')
        const WorkshopPart(
          'basket',
          WorkshopObject.cup,
          Offset(160, 244),
          scale: 1.1,
        ),
      if (project.id == 'project_47')
        const WorkshopPart(
          'jar',
          WorkshopObject.jar,
          Offset(160, 215),
          scale: .8,
        ),
    ];
    final step = WorkshopStep(
      description: project.name,
      parts: parts,
      sequence: MotionSequence(
        initial: {for (final p in parts) p.id: const MotionPose(amount: 1)},
        clips: const [],
      ),
    );
    return _SceneCrop(
      viewport: _viewports[project.id] ?? const Rect.fromLTWH(30, 45, 260, 270),
      child: Stack(
        children: [
          Positioned.fill(
            child: WorkshopStepScene(
              step: step,
              frame: step.sequence.sample(1),
            ),
          ),
          if (project.id == 'project_41')
            const Positioned(
              left: 80,
              top: 125,
              width: 160,
              height: 160,
              child: WorkshopVectorIcon(WorkshopIconKind.bag, size: 160),
            ),
          if (project.id == 'project_43') ...[
            const Positioned(
              left: 140,
              top: 18,
              width: 40,
              height: 40,
              child: WorkshopVectorIcon(WorkshopIconKind.hook, size: 40),
            ),
            const Positioned(
              left: 118,
              top: 168,
              width: 44,
              height: 44,
              child: WorkshopVectorIcon(WorkshopIconKind.onion, size: 44),
            ),
            const Positioned(
              left: 166,
              top: 168,
              width: 44,
              height: 44,
              child: WorkshopVectorIcon(WorkshopIconKind.onion, size: 44),
            ),
          ],
          Positioned.fill(
            child: CustomPaint(painter: _StaticFinishPainter(project.id)),
          ),
        ],
      ),
    );
  }
}

/// Crop empty scene margins without changing the original painter coordinates.
class _SceneCrop extends StatelessWidget {
  const _SceneCrop({required this.child, required this.viewport});
  final Widget child;
  final Rect viewport;
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.contain,
    child: ClipRect(
      child: SizedBox(
        width: viewport.width,
        height: viewport.height,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 320,
          maxWidth: 320,
          minHeight: 330,
          maxHeight: 330,
          child: Transform.translate(
            offset: -viewport.topLeft,
            child: SizedBox(width: 320, height: 330, child: child),
          ),
        ),
      ),
    ),
  );
}

/// Finished products only; these seven recipes receive no new animations.
class _StaticFinishPainter extends CustomPainter {
  const _StaticFinishPainter(this.id);
  final String id;
  static const ink = Color(0xFF193B52),
      blue = Color(0xFFC6E8F3),
      tan = Color(0xFFE4C6A0);
  Paint get line => Paint()
    ..color = ink
    ..strokeWidth = 4.5
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  void shape(Canvas c, Path p, Color color) {
    c.drawPath(p, Paint()..color = color);
    c.drawPath(p, line);
  }

  void rect(Canvas c, Rect r, Color color) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));
    c.drawRRect(rr, Paint()..color = color);
    c.drawRRect(rr, line);
  }

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 320, size.height / 330);
    switch (id) {
      case 'project_45':
        rect(c, const Rect.fromLTWH(68, 166, 184, 84), tan);
        for (var i = 0; i < 17; i++) {
          c.drawLine(
            Offset(74 + i * 10, 171),
            Offset(74 + i * 10, 245),
            line..strokeWidth = 3,
          );
        }
      case 'project_46':
        for (final x in [126.0, 194.0]) {
          rect(c, Rect.fromLTWH(x - 3, 169, 6, 84), tan);
        }
        for (final y in [193.0, 222.0]) {
          rect(c, Rect.fromLTWH(70, y, 180, 6), tan);
        }
      case 'project_41':
        shape(
          c,
          Path()
            ..moveTo(143, 111)
            ..lineTo(177, 111)
            ..lineTo(177, 135)
            ..lineTo(207, 169)
            ..lineTo(113, 169)
            ..lineTo(143, 135)
            ..close(),
          blue,
        );
        rect(c, const Rect.fromLTWH(138, 98, 44, 15), const Color(0xFF86B7D2));
        c.drawLine(
          const Offset(120, 174),
          const Offset(200, 174),
          line..color = const Color(0xFFE9A18E),
        );
      case 'project_42':
        shape(
          c,
          Path()
            ..moveTo(96, 106)
            ..lineTo(224, 106)
            ..lineTo(173, 185)
            ..lineTo(173, 226)
            ..lineTo(147, 226)
            ..lineTo(147, 185)
            ..close(),
          blue,
        );
        c.drawLine(
          const Offset(96, 106),
          const Offset(224, 106),
          line
            ..color = const Color(0xFFE9A18E)
            ..strokeWidth = 8,
        );
      case 'project_43':
        for (final point in [
          const Offset(105, 201),
          const Offset(215, 201),
          const Offset(160, 201),
        ]) {
          c.drawLine(const Offset(165, 46), point, line..strokeWidth = 3.5);
        }
        for (var i = 0; i < 5; i++) {
          c.drawCircle(Offset(126 + i * 17, 246), 2.5, Paint()..color = ink);
        }
      case 'project_47':
        c.drawRect(
          const Rect.fromLTWH(112, 251, 96, 26),
          Paint()..color = const Color(0xFFE8BE7A),
        );
        shape(
          c,
          Path()
            ..moveTo(100, 104)
            ..lineTo(220, 104)
            ..lineTo(164, 192)
            ..lineTo(156, 192)
            ..close(),
          const Color(0xFFFFFCF4),
        );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _StaticFinishPainter oldDelegate) =>
      oldDelegate.id != id;
}
