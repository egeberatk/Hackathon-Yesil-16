import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/upcycling_project.dart';
import '../services/recipe_matching_service.dart';
import '../widgets/page_body.dart';
import '../widgets/workshop_artwork.dart';
import '../widgets/recipe_badge.dart';
import '../widgets/flow_notice.dart';
import '../widgets/recipe_ingredient_group.dart';
import '../widgets/recipe_step_viewer.dart';

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
  final _steps = GlobalKey();
  void _showStep(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _steps.currentContext;
      if (mounted && context != null) {
        Scrollable.ensureVisible(context, alignment: .05);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final match = widget.match;
    return Scaffold(
      appBar: AppBar(title: const Text('Adım adım dönüşüm')),
      body: PageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 1.6,
                child: WorkshopArtwork(
                  materialId: project.requiredMaterials.first.materialId,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: RecipeBadge(
                label: project.category,
                icon: Icons.category_outlined,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              project.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              project.description,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                RecipeBadge(
                  label: '${project.estimatedMinutes} dakika',
                  icon: Icons.schedule_outlined,
                ),
                RecipeBadge(
                  label: project.difficulty,
                  icon: Icons.signal_cellular_alt_outlined,
                ),
              ],
            ),
            if (match != null) ...[
              const SizedBox(height: 24),
              if (match.canMake)
                const FlowNotice(
                  title: 'Yapabilirsin',
                  message: 'Atık malzemelerin yeterli. Başlamadan önce aşağıdaki yardımcı malzemeleri de kontrol et.',
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCF0EB),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF92452F)),
                      const SizedBox(height: 12),
                      Text(
                        'Eksik malzeme',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...match.missingMaterials.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${item.name}: ${item.quantity} adet eksik',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 28),
            RecipeIngredientGroup(
              title: 'Gereken malzemeler',
              icon: Icons.recycling_outlined,
              items: project.requiredMaterials
                  .map((item) => '${item.quantity} adet ${item.name}')
                  .toList(),
            ),
            RecipeIngredientGroup(
              title: 'Yardımcı malzemeler',
              icon: Icons.handyman_outlined,
              items: project.requiredSupplies,
              emptyMessage: 'Gerekli yardımcı malzeme belirtilmemiş.',
            ),
            if (project.optionalSupplies.isNotEmpty)
              RecipeIngredientGroup(
                title: 'İsteğe bağlı malzemeler',
                icon: Icons.add_circle_outline,
                items: project.optionalSupplies,
              ),
            Text(
              'Haydi başlayalım',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Kendi hızında, adım adım ilerle.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 20),
            RecipeStepViewer(
              key: _steps,
              project: project,
              mediaBuilder: widget.stepMediaBuilder,
              onStepChanged: _showStep,
            ),
            const SizedBox(height: 28),
            FlowNotice(title: 'Kullanım amacı', message: project.practicalUse),
            const SizedBox(height: 16),
            FlowNotice(
              title: 'Güvenlik uyarısı',
              message: project.safetyWarning.isEmpty
                  ? 'Bu tarif için güvenlik uyarısı belirtilmemiş.'
                  : project.safetyWarning,
              warning: true,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_outlined),
              label: const Text('Tariflere dön'),
            ),
          ],
        ),
      ),
    );
  }
}
