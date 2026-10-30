import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class RecipeBadge extends StatelessWidget {
  const RecipeBadge({
    super.key,
    required this.label,
    this.icon,
    this.color = AppTheme.primary,
    this.background = const Color(0xFFF0F4F1),
  });
  final String label;
  final IconData? icon;
  final Color color, background;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
