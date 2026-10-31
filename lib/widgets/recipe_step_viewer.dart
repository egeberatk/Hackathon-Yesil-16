import 'package:flutter/material.dart';

import '../models/upcycling_project.dart';
import '../core/guide_language.dart';
import '../animations/pet_planter_steps.dart';
import '../animations/workshop_steps.dart';
import 'pet_planter_scene.dart';
import 'workshop_step_scene.dart';
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
    this.onFinished,
  });
  final UpcyclingProject project;
  final RecipeStepMediaBuilder? mediaBuilder;
  final ValueChanged<int>? onStepChanged;
  final VoidCallback? onFinished;
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
    final workshop = WorkshopSteps.resolve(widget.project, _index);
    if (workshop != null) {
      return RecipeMotionPlayer(
        key: ValueKey('${widget.project.id}-workshop-$_index'),
        sequence: workshop.sequence,
        description: workshop.description,
        warning: workshop.warning,
        sceneBuilder: (context, frame) =>
            WorkshopStepScene(step: workshop, frame: frame),
      );
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
  Widget build(BuildContext context) {
    final step = PetPlanterSteps.resolve(widget.project, _index);
    final workshop = WorkshopSteps.resolve(widget.project, _index);
    final media = _media(context);
    final builtInPetMedia =
        step != null && widget.mediaBuilder == null && media != null;
    final builtInWorkshopMedia =
        workshop != null && widget.mediaBuilder == null && media != null;
    final last = _index == widget.project.steps.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: RecipeStepCard(
            number: _index + 1,
            total: widget.project.steps.length,
            text: widget.project.steps[_index],
            media: media,
            summary:
                step?.description ??
                workshop?.description ??
                GuideLanguage.neutral(widget.project.steps[_index]),
            warning: builtInPetMedia || builtInWorkshopMedia
                ? null
                : step?.warning ?? workshop?.warning,
            showText: !builtInPetMedia && !builtInWorkshopMedia,
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
              onPressed: last ? widget.onFinished : () => _go(1),
              icon: Icon(
                last && widget.onFinished != null
                    ? Icons.check_outlined
                    : Icons.arrow_forward_outlined,
              ),
              label: Text(
                last
                    ? (widget.onFinished == null ? 'Son adım' : 'Bitir')
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
}
