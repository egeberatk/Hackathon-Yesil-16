import 'package:flutter/material.dart';

class MaterialQuantityStepper extends StatelessWidget {
  const MaterialQuantityStepper({
    super.key,
    required this.quantity,
    required this.onChange,
  });
  final int quantity;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desired = MediaQuery.textScalerOf(context)
          .scale(172)
          .clamp(172.0, 240.0);
      return SizedBox(
        width: constraints.maxWidth.isFinite
            ? desired.clamp(0.0, constraints.maxWidth)
            : desired,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F5F1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Miktarı azalt',
                onPressed: quantity > 1 ? () => onChange(-1) : null,
                icon: const Icon(Icons.remove_outlined),
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  label: '$quantity adet',
                  excludeSemantics: true,
                  child: Text(
                    '$quantity adet',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Miktarı artır',
                onPressed: quantity < 999 ? () => onChange(1) : null,
                icon: const Icon(Icons.add_outlined),
              ),
            ],
          ),
        ),
      );
    },
  );
}
