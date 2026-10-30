import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class FlowNotice extends StatelessWidget {
  const FlowNotice({
    super.key,
    required this.title,
    required this.message,
    this.warning = false,
  });
  final String title, message;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFCF0EB) : const Color(0xFFEAF4ED),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          warning ? Icons.info_outline : Icons.eco_outlined,
          color: warning ? const Color(0xFF92452F) : AppTheme.primary,
        ),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppTheme.muted),
        ),
      ],
    ),
  );
}
