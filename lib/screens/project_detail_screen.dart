import 'package:flutter/material.dart';

import '../models/upcycling_project.dart';
import '../widgets/page_body.dart';

class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({super.key, required this.project});
  final UpcyclingProject project;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Adım adım dönüşüm')),
    body: PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Text(
              project.symbol,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 88),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            project.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(project.description),
          const SizedBox(height: 12),
          Chip(
            avatar: const Icon(Icons.schedule, size: 18),
            label: Text('${project.minutes} dakika · Kolay · Örnek tarif'),
          ),
          const SizedBox(height: 24),
          Text(
            'Gereken malzemeler',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...project.requirements.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('•  ${entry.value} adet ${entry.key.label}'),
            ),
          ),
          ...project.extras.map(
            (extra) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('•  $extra'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Haydi başlayalım',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...project.steps.indexed.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 16, child: Text('${step.$1 + 1}')),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(step.$2, style: const TextStyle(height: 1.6)),
                  ),
                ],
              ),
            ),
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Kesici alet kullanırken dikkatli ol; çocuklar bir yetişkinle çalışmalı. Dönüştürmeden önce malzemeleri temizle.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Ana sayfaya dön'),
            ),
          ),
        ],
      ),
    ),
  );
}
