import 'package:flutter/material.dart';

import '../models/material_item.dart';
import '../services/recipe_repository.dart';
import '../widgets/recipe_library.dart';
import '../widgets/recipe_badge.dart';
import '../widgets/eco_guide.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key, required this.items, this.repository});
  final List<MaterialItem> items;
  final RecipeRepository? repository;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dönüşüm fikirleri')),
    body: RecipeLibrary(
      items: items,
      repository: repository,
      scrollable: true,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: RecipeBadge(
              label: '03 · Projeni seç',
              icon: Icons.lightbulb_outline,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Yeni hikâyeni seç.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const EcoGuide(scene: EcoGuideScene.recommendations),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .where(
                  (item) =>
                      !item.requiresConfirmation &&
                      item.type != WasteType.unknown,
                )
                .map(
                  (item) => RecipeBadge(
                    label: '${item.quantity} × ${item.type.label}',
                    icon: Icons.check_outlined,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
