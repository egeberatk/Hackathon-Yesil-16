import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/upcycling_project.dart';
import '../screens/project_detail_screen.dart';
import '../services/recipe_matching_service.dart';
import 'recipe_badge.dart';
import 'recipe_product_photo.dart';
import 'recipe_project_preview.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    this.match,
    this.compact = false,
  });
  final UpcyclingProject project;
  final RecipeMatch? match;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.only(bottom: compact ? 0 : 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primary.withValues(alpha: .045),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ProjectDetailScreen(project: project, match: match),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: compact ? 1.7 : 1.9,
              child: RecipeProductPhoto(
                projectId: project.id,
                height: null,
                fallback: ColoredBox(
                  color: const Color(0xFFEAF4ED),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: RecipeProjectPreview(project: project),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.category.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.name,
                    maxLines: compact ? 2 : null,
                    overflow: compact ? TextOverflow.ellipsis : null,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 8),
                    Text(
                      project.description,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.muted),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      RecipeBadge(
                        label: '${project.estimatedMinutes} dk',
                        icon: Icons.schedule_outlined,
                      ),
                      RecipeBadge(
                        label: project.difficulty,
                        icon: Icons.signal_cellular_alt_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gerekli malzemeler',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  ...project.requiredMaterials.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${item.quantity} × ${item.name}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppTheme.muted),
                      ),
                    ),
                  ),
                  if (match != null) ...[
                    const SizedBox(height: 12),
                    RecipeBadge(
                      label: match!.canMake
                          ? 'Yapabilirsin'
                          : 'Eksik Malzemeli',
                      icon: match!.canMake
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      color: match!.canMake
                          ? AppTheme.primary
                          : const Color(0xFF92452F),
                      background: match!.canMake
                          ? const Color(0xFFEAF4ED)
                          : const Color(0xFFFCF0EB),
                    ),
                  ],
                  if (match != null && !match!.canMake) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Eksik malzeme',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    ...match!.missingMaterials.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${item.name}: ${item.quantity} adet eksik',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.muted),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tarifi keşfet',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppTheme.primary),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_outlined, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
