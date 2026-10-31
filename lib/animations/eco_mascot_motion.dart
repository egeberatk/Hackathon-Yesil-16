import 'dart:math' as math;

enum EcoMascotMood {
  idle,
  greeting,
  thinking,
  explaining,
  celebrating,
  warning,
}

/// Recipe animations do not depend on this separate, lightweight pose adapter.
class EcoMascotPose {
  const EcoMascotPose({
    this.lift = 0,
    this.sway = 0,
    this.head = 0,
    this.redArm = 0,
    this.blueArm = 0,
    this.leftLeg = 0,
    this.rightLeg = 0,
    this.sprout = 0,
    this.eyeOpen = 1,
  });
  final double lift,
      sway,
      head,
      redArm,
      blueArm,
      leftLeg,
      rightLeg,
      sprout,
      eyeOpen;

  static EcoMascotPose sample(EcoMascotMood mood, double progress) {
    final t = progress.clamp(0.0, 1.0);
    final wave = math.sin(t * math.pi * 2);
    final gesture = math.sin(t * math.pi);
    final blink = (1 - ((t - .67).abs() / .055)).clamp(0.0, 1.0);
    final eyes = 1 - .96 * blink;
    return switch (mood) {
      EcoMascotMood.idle => EcoMascotPose(
        lift: -5 * gesture,
        sway: 2 * wave,
        sprout: .018 * wave,
        eyeOpen: eyes,
      ),
      EcoMascotMood.greeting => EcoMascotPose(
        lift: -3 * gesture,
        redArm: .23 * math.sin(t * math.pi * 6) * gesture,
        head: .015 * wave,
        eyeOpen: eyes,
      ),
      EcoMascotMood.thinking => EcoMascotPose(
        head: -.085 * gesture,
        blueArm: .045 * gesture,
        sprout: -.03 * gesture,
        eyeOpen: eyes,
      ),
      EcoMascotMood.explaining => EcoMascotPose(
        blueArm: -.2 * gesture,
        redArm: .025 * wave,
        head: .025 * gesture,
        eyeOpen: eyes,
      ),
      EcoMascotMood.celebrating => EcoMascotPose(
        lift: -32 * gesture * gesture,
        redArm: .3 * gesture,
        blueArm: -.36 * gesture,
        leftLeg: -.045 * gesture,
        rightLeg: .045 * gesture,
        eyeOpen: 1 - .25 * gesture * gesture,
      ),
      EcoMascotMood.warning => EcoMascotPose(
        sway: 6 * wave * gesture,
        head: .04 * wave,
        blueArm: -.09 * gesture,
        eyeOpen: eyes,
      ),
    };
  }
}
