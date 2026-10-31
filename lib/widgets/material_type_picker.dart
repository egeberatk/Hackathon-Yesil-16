import 'package:flutter/material.dart';

import '../models/material_item.dart';
import '../services/material_candidate_filter.dart';
import 'material_visual.dart';
import 'material_quantity_stepper.dart';

class MaterialTypePicker extends StatefulWidget {
  const MaterialTypePicker({super.key});
  @override
  State<MaterialTypePicker> createState() => _MaterialTypePickerState();
}

class _MaterialTypePickerState extends State<MaterialTypePicker> {
  final _search = TextEditingController();
  int _quantity = 1;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = MaterialCandidateFilter.folded(_search.text.trim());
    final types = WasteType.values
        .where(
          (type) =>
              type != WasteType.unknown &&
              MaterialCandidateFilter.folded('${type.label} ${type.materialId}')
                  .contains(query),
        )
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Malzeme Ekle',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('material-search'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Malzeme ara',
                prefixIcon: Icon(Icons.search_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: MaterialQuantityStepper(
                quantity: _quantity,
                onChange: (delta) => setState(
                  () => _quantity = (_quantity + delta).clamp(1, 999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (types.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Bu isimde bir malzeme bulunamadı.'),
              ),
            for (final type in types)
              ListTile(
                key: ValueKey('pick-material-${type.materialId}'),
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                leading: MaterialVisual(type, size: 48),
                title: Text(type.label),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () => Navigator.pop(
                  context,
                  MaterialItem(type: type, quantity: _quantity),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
