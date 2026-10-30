import 'package:flutter/material.dart';

import '../animations/motion_sequence.dart';
import '../core/app_theme.dart';

typedef MotionSceneBuilder = Widget Function(
  BuildContext context,
  MotionFrame frame,
);

/// Playback and accessibility belong here; drawings and recipe data do not.
class RecipeMotionPlayer extends StatefulWidget {
  const RecipeMotionPlayer({
    super.key,
    required this.sequence,
    required this.sceneBuilder,
    required this.description,
    this.warning,
  });
  final MotionSequence sequence;
  final MotionSceneBuilder sceneBuilder;
  final String description;
  final String? warning;
  @override
  State<RecipeMotionPlayer> createState() => _RecipeMotionPlayerState();
}

class _RecipeMotionPlayerState extends State<RecipeMotionPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _paused = false;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.sequence.duration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (reduced != _reducedMotion || !_controller.isAnimating && !_paused) {
      _reducedMotion = reduced;
      _syncPlayback();
    }
  }

  @override
  void didUpdateWidget(covariant RecipeMotionPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sequence != widget.sequence) {
      _controller.stop();
      _controller.duration = widget.sequence.duration;
      _controller.value = 0;
      _paused = false;
      _syncPlayback();
    }
  }

  void _syncPlayback() {
    if (_reducedMotion) {
      _controller.stop();
      _controller.value = 1;
    } else if (_paused) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  Widget _scene(BuildContext context) {
    try {
      return widget.sceneBuilder(
        context,
        widget.sequence.sample(_controller.value),
      );
    } catch (_) {
      // Media adapters have no bearing on the independently rendered recipe text.
      return const Center(
        child: Text('Çizim gösterilemiyor. Adım metnini takip edebilirsiniz.'),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFF0F6F2),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: widget.description,
          image: true,
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: AspectRatio(
                aspectRatio: 320 / 330,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => _scene(context),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(widget.description, style: Theme.of(context).textTheme.bodyMedium),
        if (widget.warning != null) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppTheme.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.warning!)),
            ],
          ),
        ],
        const SizedBox(height: 8),
        if (_reducedMotion)
          const Text('Azaltılmış hareket açık. Adımın son durumu gösteriliyor.')
        else
          OutlinedButton.icon(
            key: const Key('motion-playback'),
            onPressed: () => setState(() {
              _paused = !_paused;
              _syncPlayback();
            }),
            icon: Icon(
              _paused ? Icons.play_arrow_outlined : Icons.pause_outlined,
            ),
            label: Text(
              _paused ? 'Animasyonu devam ettir' : 'Animasyonu duraklat',
            ),
          ),
      ],
    ),
  );
}
