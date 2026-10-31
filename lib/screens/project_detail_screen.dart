import 'package:flutter/material.dart';

import '../core/recipe_safety_copy.dart';
import '../core/guide_language.dart';
import '../models/upcycling_project.dart';
import '../services/recipe_matching_service.dart';
import '../widgets/recipe_detail_layout.dart';
import '../widgets/recipe_icon_grid.dart';
import '../widgets/recipe_library.dart';
import '../widgets/recipe_project_preview.dart';
import '../widgets/recipe_step_viewer.dart';
import 'pet_project_detail_screen.dart';
import 'workshop_recipe_guide.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({
    super.key,
    required this.project,
    this.match,
    this.stepMediaBuilder,
  });
  final UpcyclingProject project;
  final RecipeMatch? match;
  final RecipeStepMediaBuilder? stepMediaBuilder;
  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  void _openWorkshop() {
    final navigator = Navigator.of(context);
    final detailRoute = ModalRoute.of(context);
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => WorkshopRecipeGuide(
          project: widget.project,
          mediaBuilder: widget.stepMediaBuilder,
          onReturnToRecipes: () {
            if (detailRoute != null && detailRoute.isActive) {
              navigator.popUntil((route) => route == detailRoute);
              if (!detailRoute.isFirst) {
                navigator.pop();
                return;
              }
            }
            navigator.pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Projeler')),
                  body: const RecipeLibrary(showAll: true, scrollable: true),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSafety() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Güvenlik ayrıntıları',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(GuideLanguage.neutral(widget.project.safetyWarning)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    if (project.id == 'project_40') {
      return PetProjectDetailScreen(
        project: project,
        match: widget.match,
        stepMediaBuilder: widget.stepMediaBuilder,
      );
    }
    return RecipeDetailLayout(
      project: project,
      match: widget.match,
      preview: RecipeProjectPreview(project: project),
      materials: project.requiredMaterials
          .map(RecipeVisualItem.material)
          .toList(),
      supplies: RecipeVisualItem.supplies(project.requiredSupplies),
      optionalSupplies: RecipeVisualItem.supplies(project.optionalSupplies),
      safetySummary:
          RecipeSafetyCopy.summaries[project.id] ??
          (project.safetyWarning.isEmpty
              ? ''
              : 'Güvenlik ayrıntılarını incele.'),
      onSafety: _showSafety,
      onStart: _openWorkshop,
    );
  }
}
