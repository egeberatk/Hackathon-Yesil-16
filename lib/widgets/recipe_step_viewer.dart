import 'package:flutter/material.dart';

import '../models/upcycling_project.dart';
import '../animations/pet_planter_steps.dart';
import 'pet_planter_scene.dart';
import 'recipe_motion_player.dart';
import 'recipe_step_card.dart';

typedef RecipeStepMediaBuilder = Widget? Function(
  BuildContext context,
  UpcyclingProject project,
  int stepIndex,
);

class RecipeStepViewer extends StatefulWidget {
  const RecipeStepViewer({
    super.key,
    required this.project,
    this.mediaBuilder,
    this.onStepChanged,
  });
  final UpcyclingProject project;
  final RecipeStepMediaBuilder? mediaBuilder;
  final ValueChanged<int>? onStepChanged;
  @override
  State<RecipeStepViewer> createState() => _RecipeStepViewerState();
}

class _RecipeStepViewerState extends State<RecipeStepViewer> {
  int _index = 0;
  @override
  void didUpdateWidget(covariant RecipeStepViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.id != widget.project.id) _index = 0;
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.project.steps.length) return;
    setState(() => _index = next);
    widget.onStepChanged?.call(next);
  }

  Widget? _media(BuildContext context) {
    if (widget.mediaBuilder != null) {
      return widget.mediaBuilder!(context, widget.project, _index);
    }
    final step = PetPlanterSteps.resolve(widget.project, _index);
    if (step == null) return null;
    return RecipeMotionPlayer(
      key: ValueKey('${widget.project.id}-motion-$_index'),
      sequence: step.sequence,
      description: step.description,
      warning: step.warning,
      sceneBuilder: (context, frame) =>
          PetPlanterScene(frame: frame, stepIndex: _index),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        liveRegion: true,
        child: RecipeStepCard(
          number: _index + 1,
          total: widget.project.steps.length,
          text: widget.project.steps[_index],
          media: _media(context),
        ),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final previous = OutlinedButton.icon(
            key: const Key('previous-step'),
            onPressed: _index == 0 ? null : () => _go(-1),
            icon: const Icon(Icons.arrow_back_outlined),
            label: const Text('Önceki adım'),
          );
          final next = FilledButton.icon(
            key: const Key('next-step'),
            onPressed: _index == widget.project.steps.length - 1
                ? null
                : () => _go(1),
            icon: const Icon(Icons.arrow_forward_outlined),
            label: Text(
              _index == widget.project.steps.length - 1
                  ? 'Son adım'
                  : 'Sonraki adım',
            ),
          );
          if (constraints.maxWidth >= 340 &&
              MediaQuery.textScalerOf(context).scale(14) <= 18.2) {
            return Row(
              children: [
                Expanded(child: previous),
                const SizedBox(width: 12),
                Expanded(child: next),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [previous, const SizedBox(height: 12), next],
          );
        },
      ),
    ],
  );
}
