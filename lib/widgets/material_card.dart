import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/material_item.dart';
import 'material_visual.dart';
import 'material_quantity_stepper.dart';

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
    final valid = item.quantity >= 1 && item.quantity <= 999;
    final confirmed = !unknown && valid && !item.requiresConfirmation;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: confirmed ? AppTheme.secondary : AppTheme.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: .035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: unknown
                      ? const Color(0xFFFCF0EB)
                      : const Color(0xFFF0F5ED),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: MaterialVisual(item.type, size: 56),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Tooltip(
                  message: 'Malzemeyi düzenle',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onEdit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 14),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Düzenle',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Malzemeyi sil',
                onPressed: onRemove,
                icon: const Icon(Icons.close_outlined),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              MaterialQuantityStepper(
                quantity: item.quantity,
                onChange: onQuantity,
              ),
              Tooltip(
                message: confirmed ? 'Onayı geri al' : 'Malzemeyi onayla',
                child: FilterChip(
                  selected: confirmed,
                  showCheckmark: true,
                  label: Text(
                    unknown
                        ? 'Türü belirsiz'
                        : confirmed
                        ? 'Onaylandı'
                        : 'Onayla',
                  ),
                  onSelected: unknown || !valid ? null : (_) => onConfirm(),
                ),
              ),
            ],
          ),
          if (unknown || !valid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                unknown
                    ? 'Türünü seç veya listeden çıkar.'
                    : 'Adedi 1–999 arasında düzenle.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppTheme.accent),
              ),
            ),
        ],
      ),
    );
  }
}
