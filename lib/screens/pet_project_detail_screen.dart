import 'package:flutter/material.dart';

import '../core/pet_guide_copy.dart';
import '../models/upcycling_project.dart';
import '../services/recipe_matching_service.dart';
import '../widgets/page_body.dart';
import '../widgets/recipe_icon_grid.dart';
import '../widgets/recipe_step_viewer.dart';
import '../widgets/recipe_detail_layout.dart';
import '../widgets/workshop_vector_icon.dart';
import 'pet_guide_complete_screen.dart';

void _showSafety(BuildContext context, UpcyclingProject project) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Önce güvenlik',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(PetGuideCopy.safety),
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

String _safetySummary(UpcyclingProject project) => PetGuideCopy.safetySummary;

List<RecipeVisualItem> _petSupplies(UpcyclingProject project) {
  final items = <RecipeVisualItem>[];
  for (final source in project.requiredSupplies) {
    // A prepared cap replaces the need to own a drill; the hole and adult-help
    // requirement remain explicit in the cap tooltip and in step two.
    if (source.toLowerCase().contains('matkab')) continue;
    if (source.toLowerCase().contains('pamuk')) {
      items.add(
        RecipeVisualItem(
          name: PetGuideCopy.clothSupply(source),
          shortName: 'Kumaş şeridi',
          kind: WorkshopIconKind.cloth,
          caption: RegExp(r'\d+\s*cm').firstMatch(source)?.group(0) ?? '',
        ),
      );
    } else {
      items.addAll(RecipeVisualItem.supplies([source]));
    }
  }
  return items;
}

/// PET presentation adapters retain the approved copy and guide navigation.
class PetProjectDetailScreen extends StatelessWidget {
  const PetProjectDetailScreen({
    super.key,
    required this.project,
    this.match,
    this.stepMediaBuilder,
  });
  final UpcyclingProject project;
  final RecipeMatch? match;
  final RecipeStepMediaBuilder? stepMediaBuilder;

  @override
  Widget build(BuildContext context) => RecipeDetailLayout(
    project: project,
    match: match,
    preview: const Center(
      child: WorkshopVectorIcon(WorkshopIconKind.planter, size: 145),
    ),
    description: PetGuideCopy.description,
    detailsDescription: PetGuideCopy.description,
    practicalUse: PetGuideCopy.practicalUse,
    materials: project.requiredMaterials
        .map(
          (item) => item.materialId == 'plastic_cap'
              ? RecipeVisualItem(
                  id: item.materialId,
                  name: '${item.name}\n${PetGuideCopy.capNote}',
                  shortName: 'Plastik kapak',
                  kind: WorkshopIconKind.cap,
                  caption: '${item.quantity} adet',
                )
              : RecipeVisualItem.material(item),
        )
        .toList(),
    supplies: _petSupplies(project),
    optionalSupplies: RecipeVisualItem.supplies(
      project.optionalSupplies
          .map(
            (text) => text
                .replaceAll('Hazneyi', 'Alt kabı')
                .replaceAll('hazneyi', 'alt kabı'),
          )
          .toList(),
    ),
    safetySummary: _safetySummary(project),
    onSafety: () => _showSafety(context, project),
    onStart: () => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PetRecipeGuide(
          project: project,
          stepMediaBuilder: stepMediaBuilder,
        ),
      ),
    ),
  );
}

/// Uses the existing step viewer and animation without altering their playback.
class PetRecipeGuide extends StatefulWidget {
  const PetRecipeGuide({
    super.key,
    required this.project,
    this.stepMediaBuilder,
  });
  final UpcyclingProject project;
  final RecipeStepMediaBuilder? stepMediaBuilder;
  @override
  State<PetRecipeGuide> createState() => _PetRecipeGuideState();
}

class _PetRecipeGuideState extends State<PetRecipeGuide> {
  final _steps = GlobalKey();
  int _index = 0;
  bool _finishing = false;
  void _finish() {
    if (_finishing) return;
    final navigator = Navigator.of(context);
    // Remove the viewer first so its controller is disposed before navigation.
    setState(() => _finishing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const PetGuideCompleteScreen()),
        (_) => false,
      );
    });
  }

  void _changed(int index) {
    setState(() => _index = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _steps.currentContext;
      if (mounted && context != null) {
        Scrollable.ensureVisible(context, alignment: .02);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Yapım rehberi'),
      actions: [
        IconButton(
          tooltip: 'Güvenlik uyarısı',
          onPressed: () => _showSafety(context, widget.project),
          icon: const Icon(Icons.shield_outlined),
        ),
      ],
    ),
    body: _finishing
        ? const SizedBox.shrink()
        : PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Default PET media already displays the cutting/drilling warning. Keep a
                // visible fallback when a custom or unsupported media adapter is used.
                if (_index < 2 && widget.project.steps.length != 6)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_safetySummary(widget.project)),
                  ),
                RecipeStepViewer(
                  key: _steps,
                  project: widget.project,
                  mediaBuilder: widget.stepMediaBuilder,
                  onStepChanged: _changed,
                  onFinished: _finish,
                ),
              ],
            ),
          ),
  );
}
