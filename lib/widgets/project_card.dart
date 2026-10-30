import 'package:flutter/material.dart';

import '../models/upcycling_project.dart';
import '../screens/project_detail_screen.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project, this.available});
  final UpcyclingProject project;
  final bool? available;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ProjectDetailScreen(project: project),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.symbol, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 16),
            Text(project.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(project.description),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('${project.minutes} dk · Kolay')),
                if (available != null)
                  Chip(
                    label: Text(
                      available!
                          ? 'Malzemelerin yeterli'
                          : 'Ek malzeme gerekli',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Text('Tarifi keşfet'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
