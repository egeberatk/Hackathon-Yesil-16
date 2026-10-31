import 'package:flutter/material.dart';

import '../models/upcycling_project.dart';
import '../widgets/page_body.dart';
import '../widgets/recipe_step_viewer.dart';
import 'project_complete_screen.dart';

/// Package guides reuse the same viewer/player; PET's approved flow is separate.
class WorkshopRecipeGuide extends StatefulWidget {
  const WorkshopRecipeGuide({
    super.key,
    required this.project,
    this.mediaBuilder,
  });
  final UpcyclingProject project;
  final RecipeStepMediaBuilder? mediaBuilder;
  @override
  State<WorkshopRecipeGuide> createState() => _WorkshopRecipeGuideState();
}

class _WorkshopRecipeGuideState extends State<WorkshopRecipeGuide> {
  final _viewer = GlobalKey();
  bool _finishing = false;
  void _finish() {
    if (_finishing) return;
    final navigator = Navigator.of(context);
    // Dispose the player before starting the completion route transition.
    setState(() => _finishing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WorkshopCompleteScreen()),
        (_) => false,
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

class WorkshopCompleteScreen extends StatelessWidget {
  const WorkshopCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) => const ProjectCompleteScreen();
}
