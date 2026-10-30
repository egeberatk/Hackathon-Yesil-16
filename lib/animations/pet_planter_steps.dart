import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/upcycling_project.dart';
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
  static const _safety =
      'Kesme ve delmeyi yalnızca yetişkin, sabit bir altlıkta yapsın. Kesik kenarları bantla kapatın; alev veya sıcak alet kullanmayın.';

  static const steps = <RecipeAnimationStep>[
    RecipeAnimationStep(
      description: 'Kesme çizgisinden ayırın: üst parça saksı, alt parça su haznesi olacak.',
      warning: _safety,
      sequence: MotionSequence(
        initial: {},
        clips: [
          MotionClip(kind: MotionKind.split, targets: {'upper': _separated}),
        ],
      ),
    ),
    RecipeAnimationStep(
      description: 'İki kesik kenarı bantla koruyun. Yetişkin, çıkarılıp sabitlenen kapağa el matkabıyla delik açsın ve çapakları temizlesin.',
      warning: _safety,
      sequence: MotionSequence(
        initial: {
          'upper': _separated,
          'cap': MotionPose(offset: Offset(85, 35)),
        },
        clips: [
          MotionClip(kind: MotionKind.assemble, targets: {'edge': _full}),
          MotionClip(kind: MotionKind.assemble, targets: {'hole': _full}),
        ],
      ),
    ),
    RecipeAnimationStep(
      description: 'Peçete veya pamuklu kumaş şeridini kapaktan geçirin. Bir ucu toprağın içinde, diğer ucu su haznesinin tabanına kadar uzanacak. Kapağı vidalayın.',
      sequence: MotionSequence(
        initial: {
          'upper': _separated,
          'edge': _full,
          'hole': _full,
          'cap': MotionPose(offset: Offset(85, 35)),
        },
        clips: [
          MotionClip(kind: MotionKind.insert, targets: {'strip': _full}),
          MotionClip(
            kind: MotionKind.assemble,
            targets: {'cap': MotionPose(offset: Offset(0, -60))},
          ),
          MotionClip(
            kind: MotionKind.assemble,
            targets: {'cap': MotionPose(offset: Offset(0, -35))},
          ),
        ],
      ),
    ),
    RecipeAnimationStep(
      description: 'Üst parçayı 180° çevirip ağız aşağı bakacak şekilde hazneye oturtun. Peçete veya pamuklu kumaş şeridinin üst ucunu toprağa yayın; bitkiyi yerleştirip toprağı hafifçe sulayın.',
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
          MotionClip(kind: MotionKind.insert, targets: {'upper': _inverted}),
          MotionClip(kind: MotionKind.pour, targets: {'soil': _full}),
          MotionClip(kind: MotionKind.assemble, targets: {'plant': _full}),
          MotionClip(kind: MotionKind.pour, targets: {'moisture': _full}),
        ],
      ),
    ),
    RecipeAnimationStep(
      description: 'Alt hazneye su ekleyin. Su kapağın ve toprağın altında kalsın; yalnızca peçete veya pamuklu kumaş şeridinin alt ucu suya uzansın.',
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
      description: 'Üst parçayı nazikçe kaldırarak su seviyesini kontrol edin ve yerine oturtun. Toprak nemini de kontrol edin; hazneyi düzenli boşaltıp yıkayın, yakıcı güneşten koruyun.',
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
