import 'package:flutter/widgets.dart';

/// Recipe-independent movements. A clip may move several parts together.
enum MotionKind { split, rotate, insert, pour, assemble }

@immutable
class MotionPose {
  const MotionPose({
    this.offset = Offset.zero,
    this.angle = 0,
    this.amount = 0,
  });
  final Offset offset;
  final double angle;

  /// Fill, reveal or another drawing-specific normalized value.
  final double amount;

  MotionPose interpolate(MotionPose end, double t) => MotionPose(
    offset: Tween<Offset>(begin: offset, end: end.offset).transform(t),
    angle: Tween<double>(begin: angle, end: end.angle).transform(t),
    amount: Tween<double>(begin: amount, end: end.amount).transform(t),
  );
}

@immutable
class MotionClip {
  const MotionClip({
    required this.kind,
    required this.targets,
    this.duration = const Duration(milliseconds: 1400),
    this.curve = Curves.easeInOutCubic,
  });
  final MotionKind kind;

  /// Each target starts at its pose at the end of the previous clip.
  final Map<String, MotionPose> targets;
  final Duration duration;
  final Curve curve;
}

@immutable
class MotionFrame {
  const MotionFrame(this.poses, {this.activeKind, this.activeProgress = 0});
  final Map<String, MotionPose> poses;
  final MotionKind? activeKind;
  final double activeProgress;
  MotionPose operator [](String id) => poses[id] ?? const MotionPose();
}

/// Sequential clips retain finished poses. Holds make the result readable
/// before the diagram resets for its next demonstration.
@immutable
class MotionSequence {
  const MotionSequence({
    required this.initial,
    required this.clips,
    this.leadingHold = const Duration(milliseconds: 650),
    this.trailingHold = const Duration(milliseconds: 1600),
  });
  final Map<String, MotionPose> initial;
  final List<MotionClip> clips;
  final Duration leadingHold, trailingHold;
  Duration get duration => clips.fold(
    leadingHold + trailingHold,
    (sum, clip) => sum + clip.duration,
  );

  MotionFrame sample(double progress) {
    var elapsed =
        duration.inMicroseconds * progress.clamp(0.0, 1.0) -
        leadingHold.inMicroseconds;
    final poses = Map<String, MotionPose>.of(initial);
    for (final clip in clips) {
      if (elapsed < 0) break;
      final length = clip.duration.inMicroseconds;
      if (length <= 0) {
        poses.addAll(clip.targets);
        continue;
      }
      final t = (elapsed / length).clamp(0.0, 1.0);
      for (final entry in clip.targets.entries) {
        poses[entry.key] = (poses[entry.key] ?? const MotionPose()).interpolate(
          entry.value,
          clip.curve.transform(t),
        );
      }
      if (t < 1) {
        return MotionFrame(
          Map.unmodifiable(poses),
          activeKind: clip.kind,
          activeProgress: t,
        );
      }
      elapsed -= length;
    }
    return MotionFrame(Map.unmodifiable(poses));
  }
}

/// The same transform is used by widgets and by connecting lines in painters.
Offset transformMotionPoint(Offset point, Offset pivot, MotionPose pose) {
  final matrix = Matrix4.identity()..rotateZ(pose.angle);
  return MatrixUtils.transformPoint(matrix, point - pivot) +
      pivot +
      pose.offset;
}

class MotionTransform extends StatelessWidget {
  const MotionTransform({
    super.key,
    required this.pose,
    required this.pivot,
    required this.child,
  });
  final MotionPose pose;
  final Offset pivot;
  final Widget child;
  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: pose.offset,
    child: Transform.rotate(
      angle: pose.angle,
      alignment: Alignment.topLeft,
      origin: pivot,
      child: child,
    ),
  );
}
