import 'package:flutter/material.dart';

import '../models/upcycling_project.dart';
import '../widgets/page_body.dart';
import '../widgets/recipe_library.dart';
import '../widgets/recipe_step_viewer.dart';

/// Package guides reuse the same viewer/player; PET's approved flow is separate.
class WorkshopRecipeGuide extends StatefulWidget {
  const WorkshopRecipeGuide({
    super.key,
    required this.project,
    this.mediaBuilder,
    this.onReturnToRecipes,
  });
  final UpcyclingProject project;
  final RecipeStepMediaBuilder? mediaBuilder;
  final VoidCallback? onReturnToRecipes;
  @override
  State<WorkshopRecipeGuide> createState() => _WorkshopRecipeGuideState();
}

class _WorkshopRecipeGuideState extends State<WorkshopRecipeGuide> {
  final _viewer = GlobalKey();
  bool _finishing = false;
  void _finish() {
    if (_finishing) return;
    final navigator = Navigator.of(context);
    final onReturn =
        widget.onReturnToRecipes ??
        () => navigator.pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Projeler')),
              body: const RecipeLibrary(showAll: true, scrollable: true),
            ),
          ),
        );
    // Dispose the player before starting the completion route transition.
    setState(() => _finishing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => WorkshopCompleteScreen(onReturn: onReturn),
        ),
      );
    });
  }

  void _changed(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _viewer.currentContext;
      if (mounted && context != null) {
        Scrollable.ensureVisible(context, alignment: .02);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Yapım rehberi')),
    body: _finishing
        ? const SizedBox.shrink()
        : PageBody(
            child: RecipeStepViewer(
              key: _viewer,
              project: widget.project,
              mediaBuilder: widget.mediaBuilder,
              onStepChanged: _changed,
              onFinished: _finish,
            ),
          ),
  );
}

class WorkshopCompleteScreen extends StatefulWidget {
  const WorkshopCompleteScreen({super.key, required this.onReturn});
  final VoidCallback onReturn;
  @override
  State<WorkshopCompleteScreen> createState() => _WorkshopCompleteScreenState();
}

class _WorkshopCompleteScreenState extends State<WorkshopCompleteScreen> {
  bool _returning = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tamamlandı')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(0xFFEAF4ED),
                      child: Icon(
                        Icons.check_rounded,
                        size: 58,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    liveRegion: true,
                    header: true,
                    child: Text(
                      'Projen hazır!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    key: const Key('return-to-recipes'),
                    onPressed: () {
                      if (_returning) return;
                      _returning = true;
                      widget.onReturn();
                    },
                    icon: const Icon(Icons.grid_view_outlined),
                    label: const Text('Tariflere Dön'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
