import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/material_item.dart';
import '../services/demo_data_service.dart';
import '../widgets/flow_notice.dart';
import '../widgets/eco_guide.dart';
import '../widgets/material_card.dart';
import '../widgets/material_editor.dart';
import '../widgets/material_type_picker.dart';
import '../widgets/page_body.dart';
import 'projects_screen.dart';

class MaterialConfirmationScreen extends StatefulWidget {
  const MaterialConfirmationScreen({
    super.key,
    this.initialItems,
    this.candidateExplanation,
  });
  final List<MaterialItem>? initialItems;
  final String? candidateExplanation;
  @override
  State<MaterialConfirmationScreen> createState() =>
      _MaterialConfirmationScreenState();
}

List<MaterialItem> _combineDetected(List<MaterialItem> source) {
  final result = <MaterialItem>[];
  for (final original in source) {
    final item = original.copy()..requiresConfirmation = true;
    final index = item.type == WasteType.unknown
        ? -1
        : result.indexWhere((p) => p.type == item.type);
    if (index < 0) {
      result.add(item);
    } else {
      result[index].quantity += item.quantity;
    }
  }
  return result;
}

class _MaterialConfirmationScreenState
    extends State<MaterialConfirmationScreen> {
  late final _items = _combineDetected(
    widget.initialItems ?? DemoDataService.materials(),
  );
  bool _editing = false, _finding = false;
  List<MaterialItem> get _confirmed => _items
      .where(
        (item) =>
            !item.requiresConfirmation &&
            item.type != WasteType.unknown &&
            item.quantity >= 1 &&
            item.quantity <= 999,
      )
      .toList();

  Future<void> _edit({MaterialItem? item}) async {
    if (_editing) return;
    _editing = true;
    try {
      final result = await showModalBottomSheet<MaterialItem>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => item == null
            ? const MaterialTypePicker()
            : MaterialEditor(item: item),
      );
      if (!mounted || result == null) return;
      final index = _items.indexWhere(
        (p) =>
            p != item &&
            p.type == result.type &&
            result.type != WasteType.unknown,
      );
      if (index >= 0 && _items[index].quantity + result.quantity > 999) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toplam adet 999’u geçemez. Mevcut miktarı düzenle.'),
          ),
        );
        return;
      }
      setState(() {
        if (index >= 0) {
          final existing = _items[index];
          existing.quantity += result.quantity;
          existing.requiresConfirmation =
              existing.requiresConfirmation || result.requiresConfirmation;
          if (item != null) _items.remove(item);
        } else if (item == null) {
          _items.add(result);
        } else {
          _items[_items.indexOf(item)] = result;
        }
      });
    } finally {
      _editing = false;
    }
  }

  void _quantity(MaterialItem item, int delta) => setState(() {
    final next = item.quantity + delta;
    if (next < 1 || (delta > 0 && next > 999)) return;
    item.quantity = next;
    item.requiresConfirmation = true;
  });

  Future<void> _findRecipes() async {
    if (_finding || _confirmed.isEmpty) return;
    final items = _confirmed.map((item) => item.copy()).toList();
    setState(() => _finding = true);
    try {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => ProjectsScreen(items: items)),
      );
    } finally {
      if (mounted) setState(() => _finding = false);
    }
  }

  void _explain() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Fotoğrafın sonucu',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(widget.candidateExplanation!),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(toolbarHeight: 48),
    body: PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Malzemelerini Doğrula',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          if (widget.initialItems == null)
            Text(
              'Örnek liste. Malzemelerini kontrol et.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          EcoGuide(
            scene: _items.any((item) => item.type == WasteType.unknown)
                ? EcoGuideScene.caution
                : _items.isEmpty && widget.candidateExplanation != null
                ? EcoGuideScene.noMaterials
                : EcoGuideScene.materials,
          ),
          const SizedBox(height: 24),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: FlowNotice(
                title: 'Malzemelerini ekle',
                message: 'Henüz malzeme yok. Bir malzeme ekleyerek başla.',
              ),
            ),
          if (widget.candidateExplanation != null) ...[
            if (_items.isEmpty)
              const Text('Kataloğa uygun malzeme bulunamadı.'),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('candidate-explanation'),
                onPressed: _explain,
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Fotoğrafın sonucu'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          for (final item in _items)
            MaterialCard(
              key: ObjectKey(item),
              item: item,
              onEdit: () => _edit(item: item),
              onRemove: () => setState(() => _items.remove(item)),
              onQuantity: (delta) => _quantity(item, delta),
              onConfirm: () => setState(
                () => item.requiresConfirmation = !item.requiresConfirmation,
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('add-material'),
            onPressed: () => _edit(),
            icon: const Icon(Icons.add_outlined),
            label: const Text('Malzeme Ekle'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.pageInset(MediaQuery.sizeOf(context).width),
            vertical: 12,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 632),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Onayladığın malzemelere uygun projeleri bulacağız.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    key: const Key('find-recipes'),
                    onPressed: _confirmed.isEmpty || _finding
                        ? null
                        : _findRecipes,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Projeleri Keşfet',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_outlined),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
