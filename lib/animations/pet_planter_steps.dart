import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/upcycling_project.dart';
import '../core/pet_guide_copy.dart';
import 'motion_sequence.dart';

@immutable
class RecipeAnimationStep {
  const RecipeAnimationStep({
    required this.description,
    required this.sequence,
    this.warning,
  });
  final String description;
  final String? warning;
  final MotionSequence sequence;
}

/// Separate presentation metadata; the catalogue remains the source of steps.
/// Only this exact six-step recipe has a drawing adapter. Unsupported recipes
/// (or a changed step contract) fall back to the existing text view.
abstract final class PetPlanterSteps {
  static RecipeAnimationStep? resolve(UpcyclingProject project, int index) {
    if (project.id != 'project_40' ||
        project.steps.length != steps.length ||
        index < 0 ||
        index >= steps.length) {
      return null;
    }
    return steps[index];
  }

  static const _separated = MotionPose(offset: Offset(0, -35));
  static const _inverted = MotionPose(offset: Offset(0, 70), angle: math.pi);
  static const _full = MotionPose(amount: 1);
  static const steps = <RecipeAnimationStep>[
    RecipeAnimationStep(
      description: PetGuideCopy.step1,
      warning: PetGuideCopy.cuttingWarning,
      sequence: MotionSequence(
        initial: {'scissors': MotionPose(offset: Offset(125, 0), amount: 1)},
        clips: [
          MotionClip(
            kind: MotionKind.insert,
            duration: Duration(milliseconds: 700),
            targets: {'scissors': MotionPose(amount: 1)},
          ),
          MotionClip(
            kind: MotionKind.split,
            duration: Duration(milliseconds: 350),
            curve: Curves.linear,
            targets: {
              'scissors': MotionPose(offset: Offset(-18, 0)),
              'cut': MotionPose(amount: .16),
            },
          ),
          MotionClip(
            kind: MotionKind.split,
            duration: Duration(milliseconds: 350),
            curve: Curves.linear,
            targets: {
              'scissors': MotionPose(offset: Offset(-36, 0), amount: 1),
              'cut': MotionPose(amount: .33),
            },
          ),
          MotionClip(
            kind: MotionKind.split,
            duration: Duration(milliseconds: 350),
            curve: Curves.linear,
            targets: {
              'scissors': MotionPose(offset: Offset(-55, 0)),
              'cut': MotionPose(amount: .5),
            },
          ),
          MotionClip(
            kind: MotionKind.split,
            duration: Duration(milliseconds: 350),
            curve: Curves.linear,
            targets: {
              'scissors': MotionPose(offset: Offset(-73, 0), amount: 1),
              'cut': MotionPose(amount: .66),
            },
          ),
          MotionClip(
            kind: MotionKind.split,
            duration: Duration(milliseconds: 350),
            curve: Curves.linear,
            targets: {
              'scissors': MotionPose(offset: Offset(-91, 0)),
              'cut': MotionPose(amount: .83),
            },
          ),
          MotionClip(
            kind: MotionKind.split,
            duration: Duration(milliseconds: 350),
            curve: Curves.linear,
            targets: {
              'scissors': MotionPose(offset: Offset(-110, 0), amount: 1),
              'cut': _full,
            },
          ),
          MotionClip(
            kind: MotionKind.insert,
            duration: Duration(milliseconds: 650),
            targets: {'scissors': MotionPose(offset: Offset(-290, 0))},
          ),
          MotionClip(kind: MotionKind.split, targets: {'upper': _separated}),
        ],
      ),
    ),
    RecipeAnimationStep(
      description: PetGuideCopy.step2,
      warning: PetGuideCopy.holeWarning,
      sequence: MotionSequence(
        initial: {
          'upper': _separated,
          'cap': MotionPose(offset: Offset(85, 55)),
        },
        clips: [
          MotionClip(kind: MotionKind.assemble, targets: {'edge': _full}),
          MotionClip(kind: MotionKind.assemble, targets: {'hole': _full}),
        ],
      ),
    ),
    RecipeAnimationStep(
      description: PetGuideCopy.step3,
      sequence: MotionSequence(
        initial: {
          'upper': _separated,
          'edge': _full,
          'hole': _full,
          'cap': MotionPose(offset: Offset(85, 55)),
          'strip': MotionPose(offset: Offset(0, -80), amount: 1),
        },
        clips: [
          MotionClip(
            kind: MotionKind.insert,
            duration: Duration(milliseconds: 1700),
            targets: {'strip': _full},
          ),
          MotionClip(
            kind: MotionKind.assemble,
            targets: {
              'cap': MotionPose(offset: Offset(0, -60)),
              'stripSeated': _full,
            },
          ),
          MotionClip(
            kind: MotionKind.assemble,
            targets: {'cap': MotionPose(offset: Offset(0, -35))},
          ),
        ],
      ),
    ),
    RecipeAnimationStep(
      description: PetGuideCopy.step4,
      sequence: MotionSequence(
        initial: {
          'upper': _separated,
          'edge': _full,
          'hole': _full,
          'strip': _full,
        },
        clips: [
          MotionClip(
            kind: MotionKind.rotate,
            duration: Duration(milliseconds: 2200),
            targets: {
              'upper': MotionPose(offset: Offset(0, -35), angle: math.pi),
            },
          ),
          MotionClip(
            kind: MotionKind.insert,
            duration: Duration(milliseconds: 2000),
            targets: {'upper': _inverted},
          ),
          MotionClip(
            kind: MotionKind.pour,
            duration: Duration(milliseconds: 2000),
            targets: {'soil': _full},
          ),
          MotionClip(
            kind: MotionKind.assemble,
            duration: Duration(milliseconds: 1800),
            targets: {'plant': _full},
          ),
          MotionClip(kind: MotionKind.pour, targets: {'moisture': _full}),
        ],
      ),
    ),
    RecipeAnimationStep(
      description: PetGuideCopy.step5,
      sequence: MotionSequence(
        initial: {
          'upper': _inverted,
          'edge': _full,
          'hole': _full,
          'strip': _full,
          'soil': _full,
          'plant': _full,
          'moisture': _full,
        },
        clips: [
          MotionClip(
            kind: MotionKind.assemble,
            targets: {
              'upper': MotionPose(offset: Offset(0, 45), angle: math.pi),
            },
          ),
          MotionClip(
            kind: MotionKind.pour,
            duration: Duration(milliseconds: 2600),
            targets: {'water': _full},
          ),
          MotionClip(kind: MotionKind.assemble, targets: {'upper': _inverted}),
        ],
      ),
    ),
    RecipeAnimationStep(
      description: PetGuideCopy.step6,
      sequence: MotionSequence(
        initial: {
          'upper': _inverted,
          'edge': _full,
          'hole': _full,
          'strip': _full,
          'soil': _full,
          'plant': _full,
          'water': _full,
          'moisture': _full,
        },
        clips: [
          MotionClip(
            kind: MotionKind.assemble,
            targets: {
              'upper': MotionPose(offset: Offset(0, 48), angle: math.pi),
            },
          ),
          MotionClip(kind: MotionKind.assemble, targets: {'upper': _inverted}),
        ],
      ),
    ),
  ];
}
