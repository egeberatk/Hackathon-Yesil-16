import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Step text always remains available alongside optional construction media.
class RecipeStepCard extends StatelessWidget {
  const RecipeStepCard({
    super.key,
    required this.number,
    required this.total,
    required this.text,
    this.media,
    this.summary,
    this.warning,
    this.showText = true,
  });
  final int number, total;
  final String text;
  final Widget? media;
  final String? summary, warning;
  final bool showText;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppTheme.secondary),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              child: Text(
                '$number',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Adım $number / $total',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        if (media != null) ...[
          const SizedBox(height: 20),
          ClipRRect(borderRadius: BorderRadius.circular(16), child: media!),
        ],
        if (showText) ...[
          const SizedBox(height: 20),
          Text(summary ?? text, style: Theme.of(context).textTheme.bodyLarge),
        ],
        if (warning != null) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppTheme.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(warning!)),
            ],
          ),
        ],
      ],
    ),
  );
}
