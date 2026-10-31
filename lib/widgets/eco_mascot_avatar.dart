import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../animations/eco_mascot_motion.dart';

/// One decoded transparent reference adaptation, shared by the small avatars.
abstract final class EcoMascotArt {
  static const asset = 'assets/mascot/mascot_cutout.png';
  static Future<ui.Image>? _image;
  static Future<ui.Image> load() => _image ??= _decode();
  static Future<ui.Image> _decode() async {
    final bytes = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(),
      targetWidth: 900,
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }
}

class EcoMascotAvatar extends StatefulWidget {
  const EcoMascotAvatar({
    super.key,
    this.mood = EcoMascotMood.idle,
    this.size = 88,
  });
  final EcoMascotMood mood;
  final double size;
  @override
  State<EcoMascotAvatar> createState() => _EcoMascotAvatarState();
}

class _EcoMascotAvatarState extends State<EcoMascotAvatar>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..addStatusListener(_status);
  final _image = EcoMascotArt.load();
  Timer? _rest;
  bool _enabled = false, _paused = false, _played = false;
  late EcoMascotMood _mood = widget.mood;

  void _status(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_enabled) return;
    _rest?.cancel();
    if (_mood == EcoMascotMood.celebrating) {
      setState(() => _mood = EcoMascotMood.idle);
      _controller.forward(from: 0);
      return;
    }
    _rest = Timer(const Duration(seconds: 7), () {
      if (!mounted || !_enabled) return;
      setState(
        () => _mood =
            widget.mood == EcoMascotMood.greeting ||
                widget.mood == EcoMascotMood.celebrating
            ? EcoMascotMood.idle
            : widget.mood,
      );
      _controller.forward(from: 0);
    });
  }

  void _sync({bool restart = false}) {
    final media = MediaQuery.maybeOf(context);
    final enabled =
        !_paused &&
        !(media?.disableAnimations ?? false) &&
        !(media?.accessibleNavigation ?? false) &&
        TickerMode.valuesOf(context).enabled;
    if (!enabled) {
      _enabled = false;
      _rest?.cancel();
      _controller.stop();
      if ((media?.disableAnimations ?? false) ||
          (media?.accessibleNavigation ?? false)) {
        _controller.value = 1;
      }
      return;
    }
    if (!_enabled || restart) {
      _enabled = true;
      _rest?.cancel();
      if (_played && !restart && _controller.value < 1) {
        _controller.forward();
        return;
      }
      _mood = !_played || restart ? widget.mood : EcoMascotMood.idle;
      _played = true;
      _controller.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant EcoMascotAvatar old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _mood = widget.mood;
      _sync(restart: true);
    }
  }

  @override
  void dispose() {
    _rest?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    button: true,
    label: 'Karton bardak başlı çevre rehberi; kırmızı ve mavi kapak eller, turuncu ve sarı kapak ayaklar',
    child: Tooltip(
      message: _paused ? 'Maskotu devam ettir' : 'Maskotu duraklat',
      child: GestureDetector(
        onTap: () => setState(() {
          _paused = !_paused;
          _sync();
        }),
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: widget.size,
            child: FutureBuilder<ui.Image>(
              future: _image,
              builder: (context, snapshot) => snapshot.hasData
                  ? CustomPaint(
                      key: const Key('eco-mascot-paint'),
                      painter: EcoMascotPainter(
                        image: snapshot.data!,
                        mood: _mood,
                        progress: _controller,
                      ),
                    )
                  : const SizedBox.expand(),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Logical coordinates describe masks over the same cutout, not new drawings.
class EcoMascotPainter extends CustomPainter {
  EcoMascotPainter({
    required this.image,
    required this.mood,
    required this.progress,
  }) : super(repaint: progress);
  final ui.Image image;
  final EcoMascotMood mood;
  final Animation<double> progress;
  EcoMascotPose get pose => EcoMascotPose.sample(mood, progress.value);
  static const viewBox = Rect.fromLTWH(0, 0, 1000, 1000);
  static const redPivot = Offset(391, 563),
      bluePivot = Offset(615, 563),
      neckPivot = Offset(500, 526);
  static Path polygon(List<Offset> points) => Path()..addPolygon(points, true);
  static final redMask = polygon(const [
    Offset(40, 245),
    Offset(286, 245),
    Offset(291, 492),
    Offset(349, 514),
    Offset(378, 530),
    Offset(378, 650),
    Offset(277, 650),
    Offset(148, 575),
    Offset(40, 440),
  ]);
  static final blueMask = polygon(const [
    Offset(623, 538),
    Offset(636, 524),
    Offset(674, 551),
    Offset(744, 517),
    Offset(783, 468),
    Offset(977, 459),
    Offset(977, 632),
    Offset(879, 671),
    Offset(755, 697),
    Offset(623, 666),
  ]);
  static final headMask = polygon(const [
    Offset(350, 145),
    Offset(650, 145),
    Offset(713, 478),
    Offset(700, 512),
    Offset(624, 514),
    Offset(624, 537),
    Offset(377, 537),
    Offset(377, 514),
    Offset(298, 511),
    Offset(298, 476),
  ]);

  void _image(Canvas canvas) => canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    viewBox,
    Paint()..filterQuality = FilterQuality.medium,
  );
  void _layer(Canvas canvas, Path mask, Offset pivot, double angle) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
    canvas.clipPath(mask);
    _image(canvas);
    canvas.restore();
  }

  void _rectLayer(Canvas canvas, Rect rect, Offset pivot, double angle) =>
      _layer(canvas, Path()..addRect(rect), pivot, angle);

  @override
  void paint(Canvas canvas, Size size) {
    final p = pose;
    final scale = size.shortestSide / 1000;
    canvas.save();
    canvas.translate(
      (size.width - 1000 * scale) / 2,
      (size.height - 1000 * scale) / 2,
    );
    canvas.scale(scale);
    canvas.translate(p.sway, p.lift);
    _rectLayer(
      canvas,
      const Rect.fromLTRB(300, 738, 513, 985),
      const Offset(447, 745),
      p.leftLeg,
    );
    _rectLayer(
      canvas,
      const Rect.fromLTRB(513, 738, 710, 985),
      const Offset(559, 745),
      p.rightLeg,
    );
    _layer(canvas, redMask, redPivot, p.redArm);
    _layer(canvas, blueMask, bluePivot, p.blueArm);
    _rectLayer(
      canvas,
      const Rect.fromLTRB(379, 502, 622, 750),
      const Offset(500, 600),
      0,
    );
    canvas.save();
    canvas.translate(neckPivot.dx, neckPivot.dy);
    canvas.rotate(p.head);
    canvas.translate(-neckPivot.dx, -neckPivot.dy);
    _layer(canvas, headMask, Offset.zero, 0);
    _rectLayer(
      canvas,
      const Rect.fromLTRB(350, 0, 650, 148),
      const Offset(500, 149),
      p.sprout,
    );
    if (p.eyeOpen < .995) {
      for (final eye in [
        const Rect.fromLTWH(444, 316, 53, 85),
        const Rect.fromLTWH(552, 316, 53, 85),
      ]) {
        canvas.saveLayer(eye.inflate(6), Paint());
        // Match the reference cup's left-to-right lighting; feather the patch
        // so closing an eye does not expose a stretched paper-texture seam.
        canvas.drawRect(
          eye.inflate(6),
          Paint()
            ..shader = ui.Gradient.linear(
              eye.centerLeft,
              eye.centerRight,
              eye.left < 500
                  ? [const Color(0xFF96633C), const Color(0xFFAE8259)]
                  : [const Color(0xFFCDA982), const Color(0xFFDEBE9F)],
            ),
        );
        canvas.save();
        canvas.translate(eye.center.dx, eye.center.dy);
        canvas.scale(eye.width / 2, eye.height / 2);
        canvas.drawRect(
          const Rect.fromLTWH(-1.5, -1.5, 3, 3),
          Paint()
            ..blendMode = BlendMode.dstIn
            ..shader = ui.Gradient.radial(
              Offset.zero,
              1.2,
              [Colors.white, Colors.white, Colors.transparent],
              [0, .78, 1],
            ),
        );
        canvas.restore();
        canvas.restore();
        canvas.save();
        canvas.translate(eye.center.dx, eye.center.dy);
        canvas.scale(1, p.eyeOpen);
        canvas.translate(-eye.center.dx, -eye.center.dy);
        canvas.clipRect(eye);
        _image(canvas);
        canvas.restore();
      }
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant EcoMascotPainter old) =>
      old.image != image || old.mood != mood || old.progress != progress;
}
