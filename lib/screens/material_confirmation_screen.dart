import 'package:flutter/material.dart';

import '../models/material_item.dart';
import '../services/demo_data_service.dart';
import '../widgets/page_body.dart';
import 'projects_screen.dart';

class MaterialConfirmationScreen extends StatefulWidget {
  const MaterialConfirmationScreen({super.key, this.initialItems});
  // null: örnek veri, boş liste: manuel giriş, dolu liste: analiz sonucu.
  final List<MaterialItem>? initialItems;
  @override
  State<MaterialConfirmationScreen> createState() =>
      _MaterialConfirmationScreenState();
}

class _MaterialConfirmationScreenState
    extends State<MaterialConfirmationScreen> {
  late final List<MaterialItem> _items =
      widget.initialItems?.map((item) => item.copy()).toList() ??
      DemoDataService.materials();
  Future<void> _edit({MaterialItem? item}) async {
    var type = item?.type ?? WasteType.glass;
    final count = TextEditingController(text: '${item?.quantity ?? 1}');
    final name = TextEditingController(
      text: item?.name ?? WasteType.glass.label,
    );
    final form = GlobalKey<FormState>();
    final result = await showDialog<MaterialItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Malzeme ekle' : 'Malzemeyi düzenle'),
        content: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('material-name'),
                  controller: name,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Nesne adı'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nesne adını gir.'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<WasteType>(
                  initialValue: type,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Malzeme türü'),
                  validator: (value) =>
                      value == null || value == WasteType.unknown
                      ? 'Uygun bir tür seç veya nesneyi listeden sil.'
                      : null,
                  items: WasteType.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) type = value;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('material-quantity'),
                  controller: count,
                  decoration: const InputDecoration(labelText: 'Adet'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final number = int.tryParse(value ?? '');
                    return number == null || number < 1 || number > 999
                        ? '1 ile 999 arasında tam sayı gir.'
                        : null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(
                  context,
                  MaterialItem(
                    type: type,
                    name: name.text.trim(),
                    quantity: int.parse(count.text),
                  ),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    // Diyalog kapanış animasyonu sırasında denetleyicinin kullanımı sürebilir.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    count.dispose();
    name.dispose();
    if (!mounted || result == null) return;
    setState(() {
      if (item == null) {
        _items.add(result);
      } else {
        _items[_items.indexOf(item)] = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Malzemelerini onayla')),
    body: PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('2 / 3 · Malzemeler'),
          const SizedBox(height: 16),
          Text(
            'Elinde neler var?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            widget.initialItems == null
                ? 'Bu liste örnektir; fotoğraftan tespit edilmedi. Tür ve adetleri kontrol et, eksikleri ekle.'
                : 'Nesne, tür ve adetleri kontrol et. Onay gereken nesneleri düzenleyip kaydet veya sil. Bilinmeyen nesneleri uygun olmayan bir türe zorlama.',
          ),
          const SizedBox(height: 24),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Henüz malzeme yok. Bir malzeme ekleyerek başla.'),
            ),
          ..._items.map(
            (item) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(item.type.label),
                    if (item.requiresConfirmation ||
                        item.type == WasteType.unknown)
                      Text(
                        item.type == WasteType.unknown
                            ? 'Bilinmeyen nesne · Tür seçimi veya silme gerekli'
                            : 'Onay gerekli · ${item.confidence == 'uncertain' ? 'Belirsiz tespit' : 'Lütfen kontrol et'}',
                      ),
                    Row(
                      children: [
                        Expanded(child: Text('${item.quantity} adet')),
                        IconButton(
                          tooltip: 'Malzemeyi düzenle',
                          onPressed: () => _edit(item: item),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Malzemeyi sil',
                          onPressed: () => setState(() => _items.remove(item)),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: const Text('Malzeme ekle'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed:
                _items.isEmpty ||
                    _items.any(
                      (item) =>
                          item.requiresConfirmation ||
                          item.type == WasteType.unknown,
                    )
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ProjectsScreen(
                        items: _items.map((item) => item.copy()).toList(),
                      ),
                    ),
                  ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Onayla ve projeleri gör'),
          ),
        ],
      ),
    ),
  );
}
