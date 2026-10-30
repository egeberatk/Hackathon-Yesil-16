import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/material_item.dart';
import '../services/demo_data_service.dart';
import '../widgets/flow_notice.dart';
import '../widgets/material_card.dart';
import '../widgets/material_editor.dart';
import '../widgets/page_body.dart';
import '../widgets/recipe_badge.dart';
import 'projects_screen.dart';

class MaterialConfirmationScreen extends StatefulWidget {
  const MaterialConfirmationScreen({super.key, this.initialItems});
  // null: example list; []: manual entry. Every detected row needs user consent.
  final List<MaterialItem>? initialItems;
  @override
  State<MaterialConfirmationScreen> createState() =>
      _MaterialConfirmationScreenState();
}

class _MaterialConfirmationScreenState
    extends State<MaterialConfirmationScreen> {
  late final List<MaterialItem> _items =
      (widget.initialItems ?? DemoDataService.materials())
          .map((item) => item.copy()..requiresConfirmation = true)
          .toList();
  bool _editing = false;
  bool _finding = false;
  List<MaterialItem> get _confirmed => _items
      .where(
        (item) => !item.requiresConfirmation && item.type != WasteType.unknown,
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
        builder: (_) => MaterialEditor(item: item),
      );
      if (!mounted || result == null) return;
      setState(() {
        if (item == null) {
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
    item.quantity = (item.quantity + delta).clamp(1, 999);
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Malzemelerini onayla')),
    body: PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: RecipeBadge(
              label: '02 · Malzemeler',
              icon: Icons.fact_check_outlined,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Elindekiler, yeni fikirlerin.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            widget.initialItems == null
                ? 'Bu liste örnektir; fotoğraftan tespit edilmedi. Malzemelerini kontrol edip onayla.'
                : 'Türleri ve adetleri kontrol et. Yalnızca onayladığın malzemelerle tarif arayacağız.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 24),
          if (_items.isEmpty)
            const FlowNotice(
              title: 'Malzemelerini ekle',
              message: 'Henüz malzeme yok. Bir malzeme ekleyerek başla.',
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _confirmed.isEmpty
                    ? 'Henüz onayladığın malzeme yok. Kartlardan seçim yap.'
                    : 'Onaylanmayan malzemeler tarif aramasına katılmaz.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ..._items.map(
            (item) => MaterialCard(
              key: ObjectKey(item),
              item: item,
              onEdit: () => _edit(item: item),
              onRemove: () => setState(() => _items.remove(item)),
              onQuantity: (delta) => _quantity(item, delta),
              onConfirm: () => setState(
                () => item.requiresConfirmation = !item.requiresConfirmation,
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add_outlined),
            label: const Text('Malzeme ekle'),
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
            vertical: 16,
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
                    _confirmed.isEmpty
                        ? 'Devam etmek için en az bir malzemeyi onayla.'
                        : 'Yalnızca onayladığın malzemeler kullanılacak.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('find-recipes'),
                    onPressed: _confirmed.isEmpty || _finding
                        ? null
                        : _findRecipes,
                    icon: const Icon(Icons.arrow_forward_outlined),
                    label: const Text('Tarifleri Bul'),
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
