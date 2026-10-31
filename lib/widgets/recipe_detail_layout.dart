import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/upcycling_project.dart';
import '../services/recipe_matching_service.dart';
import 'page_body.dart';
import 'recipe_badge.dart';
import 'recipe_icon_grid.dart';
import 'recipe_product_photo.dart';

/// One visual overview for every recipe; guide navigation is injected.
class RecipeDetailLayout extends StatelessWidget {
  const RecipeDetailLayout({
    super.key,
    required this.project,
    required this.preview,
    required this.materials,
    required this.supplies,
    required this.optionalSupplies,
    required this.safetySummary,
    required this.onSafety,
    required this.onStart,
    this.match,
    this.description,
    this.detailsDescription,
    this.practicalUse,
  });
  final UpcyclingProject project;
  final Widget preview;
  final List<RecipeVisualItem> materials, supplies, optionalSupplies;
  final String safetySummary;
  final String? description, detailsDescription, practicalUse;
  final VoidCallback onSafety, onStart;
  final RecipeMatch? match;

  Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Proje detayı'),
      actions: [
        if (safetySummary.isNotEmpty)
          IconButton(
            tooltip: 'Güvenlik uyarısı',
            onPressed: onSafety,
            icon: const Icon(Icons.shield_outlined),
          ),
      ],
    ),
    body: PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: RecipeBadge(
              label: project.category,
              icon: Icons.category_outlined,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            image: true,
            label: '${project.name}: tamamlanmış proje',
            child: RecipeProductPhoto(
              projectId: project.id,
              fallback: Container(
                key: const Key('finished-project-preview'),
                height: 210,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4ED),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: preview,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            project.name,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 8),
          Text(
            description ?? project.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          if (match != null) ...[
            const SizedBox(height: 16),
            if (match!.canMake)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline),
                    SizedBox(width: 10),
                    Expanded(child: Text('Bu projeyi yapabilirsin!')),
                  ],
                ),
              )
            else ...[
              Text(
                'Eksik malzemeler',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              RecipeIconGrid(
                key: const Key('missing-material-icons'),
                showNames: true,
                items: [
                  for (final item in match!.missingMaterials)
                    RecipeVisualItem(
                      id: item.materialId,
                      name: item.name,
                      shortName: RecipeVisualItem.materialLabel(
                        item.materialId,
                      ),
                      kind: RecipeVisualItem.materialIcon(item.materialId),
                      caption: '${item.quantity} eksik',
                    ),
                ],
              ),
            ],
          ],
          _heading(context, 'Gereken malzemeler'),
          RecipeIconGrid(
            key: const Key('required-material-icons'),
            items: materials,
            showNames: true,
          ),
          if (supplies.isNotEmpty) ...[
            _heading(context, 'Yardımcı araçlar'),
            RecipeIconGrid(
              key: const Key('required-supply-icons'),
              items: supplies,
              showNames: true,
            ),
          ],
          if (optionalSupplies.isNotEmpty) ...[
            _heading(context, 'İsteğe bağlı'),
            RecipeIconGrid(
              key: const Key('optional-supply-icons'),
              items: optionalSupplies,
              showNames: true,
            ),
          ],
          if (safetySummary.isNotEmpty) ...[
            const SizedBox(height: 14),
            InkWell(
              key: const Key('short-safety-note'),
              onTap: onSafety,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 22,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        safetySummary,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            ),
          ],
          ExpansionTile(
            key: const Key('recipe-extra-info'),
            tilePadding: EdgeInsets.zero,
            title: const Text('Ayrıntı'),
            childrenPadding: const EdgeInsets.only(bottom: 16),
            children: [
              Text(detailsDescription ?? description ?? project.description),
              const SizedBox(height: 12),
              Text(practicalUse ?? project.practicalUse),
            ],
          ),
        ],
      ),
    ),
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.pageInset(MediaQuery.sizeOf(context).width),
            vertical: 12,
          ),
          child: FilledButton.icon(
            key: const Key('start-building'),
            onPressed: onStart,
            icon: const Icon(Icons.arrow_forward_outlined),
            label: const Text('Yapıma Başla'),
          ),
        ),
      ),
    ),
  );
}
