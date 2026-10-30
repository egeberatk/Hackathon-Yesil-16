import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/material_item.dart';
import 'recipe_badge.dart';

class MaterialCard extends StatelessWidget {
  const MaterialCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onRemove,
    required this.onQuantity,
    required this.onConfirm,
  });
  final MaterialItem item;
  final VoidCallback onEdit, onRemove, onConfirm;
  final ValueChanged<int> onQuantity;
  @override
  Widget build(BuildContext context) {
    final unknown = item.type == WasteType.unknown;
    final confirmed = !unknown && !item.requiresConfirmation;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: confirmed ? AppTheme.secondary : AppTheme.border,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: unknown
                      ? const Color(0xFFFCF0EB)
                      : const Color(0xFFEAF4ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  unknown ? Icons.help_outline : Icons.recycling_outlined,
                  color: unknown ? const Color(0xFF92452F) : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (item.name != item.type.label) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.type.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: RecipeBadge(
              label: unknown
                  ? 'Türü belirsiz'
                  : confirmed
                  ? 'Onaylandı'
                  : 'Onayını bekliyor',
              icon: unknown
                  ? Icons.help_outline
                  : confirmed
                  ? Icons.check_circle_outline
                  : Icons.fact_check_outlined,
              color: unknown ? const Color(0xFF92452F) : AppTheme.primary,
              background: unknown
                  ? const Color(0xFFFCF0EB)
                  : const Color(0xFFF0F4F1),
            ),
          ),
          if (unknown) ...[
            const SizedBox(height: 10),
            const Text(
              'Bu nesne otomatik eşleştirilmez. Türünü düzenle veya listeden çıkar.',
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Miktarı azalt',
                    onPressed: item.quantity > 1 ? () => onQuantity(-1) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '${item.quantity} adet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    tooltip: 'Miktarı artır',
                    onPressed: item.quantity < 999 ? () => onQuantity(1) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Malzemeyi düzenle',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Malzemeyi sil',
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: unknown ? null : onConfirm,
            icon: Icon(
              confirmed ? Icons.check_circle_outline : Icons.check_outlined,
            ),
            label: Text(confirmed ? 'Onayı geri al' : 'Onayla'),
          ),
        ],
      ),
    );
  }
}
