import 'package:flutter/material.dart';

import '../animations/motion_sequence.dart';
import 'pet_planter_parts.dart';
import 'pet_cutting_illustration.dart';

/// Independent flat vector parts, positioned by the existing motion engine.
class PetPlanterScene extends StatelessWidget {
  const PetPlanterScene({
    super.key,
    required this.frame,
    required this.stepIndex,
  });
  final MotionFrame frame;
  final int stepIndex;
  static const cutOrigin = PetPlanterGeometry.cutOrigin;
  static const pivot = PetPlanterGeometry.pivot;
  static const waterSurface = PetPlanterGeometry.waterSurface;
  static const stripEnd = PetPlanterGeometry.stripEnd;

  @override
  Widget build(BuildContext context) {
    final separated = stepIndex > 0 || frame['cut'].amount >= 1;
    final attachedCap = stepIndex != 1 && stepIndex != 2;
    final edge = frame['edge'].amount;
    final hole = frame['hole'].amount;
    final cuttingPreview = stepIndex == 0;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 320,
          height: 330,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                willChange: true,
                painter: cuttingPreview
                    ? PetCuttingBottlePainter(
                        upper: false,
                        separated: separated,
                      )
                    : PetReservoirPainter(separated: separated, edge: edge),
              ),
              CustomPaint(
                willChange: true,
                painter: PetWaterPainter(frame['water'].amount),
              ),
              MotionTransform(
                pose: frame['upper'],
                pivot: pivot,
                child: CustomPaint(
                  willChange: true,
                  painter: cuttingPreview
                      ? PetCuttingBottlePainter(
                          upper: true,
                          separated: separated,
                        )
                      : PetUpperBottlePainter(
                          separated: separated,
                          edge: edge,
                          cap: attachedCap,
                          hole: hole,
                        ),
                  foregroundPainter: cuttingPreview
                      ? null
                      : PetUpperBottlePainter(
                          separated: separated,
                          edge: edge,
                          cap: attachedCap,
                          hole: hole,
                          outlineOnly: true,
                        ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        willChange: true,
                        painter: PetSoilPainter(frame['soil'].amount),
                      ),
                      CustomPaint(
                        willChange: true,
                        painter: PetPlantPainter(frame['plant'].amount),
                      ),
                    ],
                  ),
                ),
              ),
              if (!attachedCap)
                MotionTransform(
                  pose: frame['cap'],
                  pivot: const Offset(160, 65),
                  child: CustomPaint(
                    willChange: true,
                    painter: PetCapPainter(hole),
                  ),
                ),
              CustomPaint(
                willChange: true,
                painter: PetStripPainter(frame, stepIndex),
              ),
              if (stepIndex == 0) ...[
                CustomPaint(
                  willChange: true,
                  painter: PetCuttingGuidePainter(frame['cut'].amount),
                ),
                MotionTransform(
                  pose: frame['scissors'],
                  pivot: PetPlanterGeometry.scissorsTip,
                  child: CustomPaint(
                    willChange: true,
                    painter: PetCuttingScissorsPainter(
                      frame['scissors'].amount,
                    ),
                  ),
                ),
              ],
              CustomPaint(willChange: true, painter: PetPourPainter(frame)),
            ],
          ),
        ),
      ),
    );
  }
}
