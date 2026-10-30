import 'package:flutter/material.dart';

import '../models/material_item.dart';
import '../services/demo_data_service.dart';
import '../widgets/page_body.dart';
import '../widgets/project_card.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key, required this.items});
  final List<MaterialItem> items;
  @override
  Widget build(BuildContext context) {
    final projects = [...DemoDataService.projects]
      ..sort(
        (a, b) => (DemoDataService.canMake(b, items) ? 1 : 0).compareTo(
          DemoDataService.canMake(a, items) ? 1 : 0,
        ),
      );
    return Scaffold(
      appBar: AppBar(title: const Text('Dönüşüm fikirleri')),
      body: PageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('3 / 3 · Projeni seç'),
            const SizedBox(height: 16),
            Text(
              'Yeni hikâyeni seç.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Örnek tarifler, onayladığın malzemelerin yeterliliğine göre sıralandı. Yardımcı malzemeleri tarifte kontrol et.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => Chip(
                      label: Text('${item.quantity} × ${item.type.label}'),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            ...projects.map(
              (project) => ProjectCard(
                project: project,
                available: DemoDataService.canMake(project, items),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
