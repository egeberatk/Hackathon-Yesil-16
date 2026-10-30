import 'package:flutter/material.dart';

import '../models/material_item.dart';

class MaterialEditor extends StatefulWidget {
  const MaterialEditor({super.key, this.item});
  final MaterialItem? item;
  @override
  State<MaterialEditor> createState() => _MaterialEditorState();
}

class _MaterialEditorState extends State<MaterialEditor> {
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  late WasteType _type = widget.item?.type ?? WasteType.glass;
  late final _name = TextEditingController(
    text: widget.item?.name ?? _type.label,
  );
  late final _quantity = TextEditingController(
    text: '${widget.item?.quantity ?? 1}',
  );
  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedPadding(
    duration: const Duration(milliseconds: 160),
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.item == null ? 'Malzeme ekle' : 'Malzemeyi düzenle',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Adını, türünü ve adedini kontrol edip kaydet.'),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('material-name'),
              controller: _name,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Nesne adı',
                errorMaxLines: 3,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nesne adını gir.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WasteType>(
              initialValue: _type,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Malzeme türü',
                errorMaxLines: 4,
              ),
              validator: (value) => value == null || value == WasteType.unknown
                  ? 'Uygun bir tür seç veya nesneyi listeden sil.'
                  : null,
              items: WasteType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  if (_name.text == _type.label) _name.text = value.label;
                  _type = value;
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('material-quantity'),
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Adet',
                errorMaxLines: 3,
              ),
              validator: (value) {
                final count = int.tryParse(value ?? '');
                return count == null || count < 1 || count > 999
                    ? '1 ile 999 arasında tam sayı gir.'
                    : null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (!_saving && _form.currentState!.validate()) {
                  _saving = true;
                  Navigator.pop(
                    context,
                    MaterialItem(
                      type: _type,
                      quantity: int.parse(_quantity.text),
                      name: _name.text.trim(),
                    ),
                  );
                }
              },
              child: const Text('Kaydet'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
          ],
        ),
      ),
    ),
  );
}
