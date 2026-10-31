import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/guide_language.dart';
import '../models/upcycling_project.dart';
import 'workshop_vector_icon.dart';

class RecipeVisualItem {
  const RecipeVisualItem({
    required this.name,
    required this.kind,
    this.caption = '',
    this.id,
    this.shortName,
  });
  final String name, caption;
  final String? shortName;
  String get displayName => shortName ?? name.split('\n').first;
  final WorkshopIconKind kind;
  final String? id;
  static String materialLabel(String id) => switch (id) {
    'pet_bottle' => 'PET şişe',
    'plastic_cap' => 'Plastik kapak',
    'glass_jar' => 'Cam kavanoz',
    'cardboard_box' => 'Karton kutu',
    'cardboard_roll' => 'Karton rulo',
    'clean_paper' => 'Kâğıt',
    'yogurt_container' => 'Yoğurt kabı',
    'egg_carton' => 'Yumurta kolisi',
    'paper_cup' => 'Kâğıt bardak',
    _ => 'Malzeme',
  };
  static WorkshopIconKind materialIcon(String id) => switch (id) {
    'pet_bottle' => WorkshopIconKind.petBottle,
    'plastic_cap' => WorkshopIconKind.cap,
    'glass_jar' => WorkshopIconKind.jar,
    'cardboard_box' => WorkshopIconKind.box,
    'cardboard_roll' => WorkshopIconKind.roll,
    'clean_paper' => WorkshopIconKind.paper,
    'yogurt_container' => WorkshopIconKind.yogurt,
    'egg_carton' => WorkshopIconKind.eggCarton,
    'paper_cup' => WorkshopIconKind.paperCup,
    _ => WorkshopIconKind.other,
  };
  factory RecipeVisualItem.material(RequiredMaterial value) => RecipeVisualItem(
    id: value.materialId,
    name: value.name,
    shortName: materialLabel(value.materialId),
    kind: materialIcon(value.materialId),
    caption: '${value.quantity} adet',
  );

  /// Presentation only: preserves the complete original text for every item.
  /// Unknown supplies remain available as an information tile.
  static List<RecipeVisualItem> supplies(List<String> sources) {
    const tools = [
      (r'\bpamuk|\bkordon|\bkurdele|\bip\b', 'Kordon', WorkshopIconKind.cord),
      (r'topra', 'Toprak', WorkshopIconKind.soil),
      (r'bitki', 'Bitki', WorkshopIconKind.plant),
      (r'\bsu\b', 'Su', WorkshopIconKind.water),
      (r'makas', 'Makas', WorkshopIconKind.scissors),
      (r'cetvel', 'Cetvel', WorkshopIconKind.ruler),
      (r'kalem', 'Kalem', WorkshopIconKind.pencil),
      (r'altli|kaymaz mat', 'Altlık', WorkshopIconKind.mat),
      (r'matkab', 'El matkabı', WorkshopIconKind.drill),
      (r'bant', 'Bant', WorkshopIconKind.tape),
      (r'yapistirici', 'Yapıştırıcı', WorkshopIconKind.glue),
      (r'kumas', 'Kumaş', WorkshopIconKind.cloth),
      (r'\btop\b', 'Top', WorkshopIconKind.ball),
      (r'fasulye|oyun tasi', 'Oyun taşı', WorkshopIconKind.stone),
      (r'sabun|deterjan', 'Sabun', WorkshopIconKind.soap),
      (r'sirke', 'Sirke', WorkshopIconKind.vinegar),
      (r'poset', 'Poşet', WorkshopIconKind.bag),
      (r'kanca|aski halkasi|saklama halkasi', 'Askı', WorkshopIconKind.hook),
      (r'sogan|sarimsak', 'Soğan / sarımsak', WorkshopIconKind.onion),
      (r'maket bicagi', 'Maket bıçağı', WorkshopIconKind.knife),
      (r'fotograf|cizim', 'Fotoğraf / çizim', WorkshopIconKind.photo),
      (
        r'etiket|cikartma|kural karti|yapiskanli kagit',
        'Etiket / kâğıt',
        WorkshopIconKind.label,
      ),
      (r'alici kap', 'Alıcı kap', WorkshopIconKind.yogurt),
      (r'kuru, gida disi malzeme', 'Kuru malzeme', WorkshopIconKind.stone),
    ];
    final result = <RecipeVisualItem>[];
    for (final source in sources) {
      final lower = source
          .toLowerCase()
          .replaceAll('ı', 'i')
          .replaceAll('ş', 's')
          .replaceAll('ğ', 'g')
          .replaceAll('ç', 'c')
          .replaceAll('ü', 'u')
          .replaceAll('ö', 'o');
      final matches = tools
          .where((tool) => RegExp(tool.$1).hasMatch(lower))
          .toList();
      if (matches.isEmpty) {
        result.add(
          RecipeVisualItem(name: source, kind: WorkshopIconKind.other),
        );
      } else {
        for (final tool in matches) {
          final cutterAlternative = lower.contains('makas veya maket bicagi');
          if (cutterAlternative && tool.$3 == WorkshopIconKind.knife) continue;
          final label = switch (tool.$3) {
            WorkshopIconKind.scissors when cutterAlternative => 'Makas / bıçak',
            WorkshopIconKind.soap when lower.contains('deterjan') => 'Deterjan',
            WorkshopIconKind.cord when lower.contains('kurdele') =>
              'İp / kurdele',
            _ => tool.$2,
          };
          final length = switch (tool.$3) {
            WorkshopIconKind.cord =>
              RegExp(r'\d+\s*cm').firstMatch(source)?.group(0) ?? '',
            WorkshopIconKind.stone =>
              RegExp(r'\d+\s*adet').firstMatch(source)?.group(0) ?? '',
            WorkshopIconKind.pencil =>
              RegExp(r'^\d+\s*adet').firstMatch(source)?.group(0) ?? '',
            WorkshopIconKind.vinegar =>
              RegExp(r'\d+\s*ml').firstMatch(source)?.group(0) ?? '',
            WorkshopIconKind.soap =>
              RegExp(r'\d+\s*damla').firstMatch(source)?.group(0) ?? '',
            _ => '',
          };
          result.add(
            RecipeVisualItem(
              name: '$label\n${GuideLanguage.neutral(source)}',
              shortName: label,
              kind: tool.$3,
              caption:
                  tool.$3 == WorkshopIconKind.cord &&
                      lower.startsWith('uc ') &&
                      length.isNotEmpty
                  ? '3 × $length'
                  : length,
            ),
          );
        }
      }
    }
    return result;
  }
}

class RecipeIconGrid extends StatelessWidget {
  const RecipeIconGrid({
    super.key,
    required this.items,
    this.showNames = false,
  });
  final List<RecipeVisualItem> items;
  final bool showNames;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final minWidth = showNames
          ? 104 * MediaQuery.textScalerOf(context).scale(14).clamp(14, 21) / 14
          : 78;
      final count = (constraints.maxWidth / minWidth).floor().clamp(1, 4);
      final width = (constraints.maxWidth - (count - 1) * 8) / count;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < items.length; i++)
            SizedBox(
              width: width,
              child: RecipeIconTile(
                key: ValueKey('visual-item-${items[i].id ?? i}'),
                item: items[i],
                showName: showNames,
              ),
            ),
        ],
      );
    },
  );
}

class RecipeIconTile extends StatefulWidget {
  const RecipeIconTile({super.key, required this.item, this.showName = false});
  final RecipeVisualItem item;
  final bool showName;
  @override
  State<RecipeIconTile> createState() => _RecipeIconTileState();
}

class _RecipeIconTileState extends State<RecipeIconTile> {
  final _tooltip = GlobalKey<TooltipState>();
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final message =
        '${item.name}${item.caption.isEmpty ? '' : '\n${item.caption}'}';
    return Semantics(
      label: message,
      child: Tooltip(
        key: _tooltip,
        message: message,
        triggerMode: TooltipTriggerMode.manual,
        excludeFromSemantics: true,
        showDuration: const Duration(seconds: 5),
        constraints: BoxConstraints(
          maxWidth: math.min(320, MediaQuery.sizeOf(context).width - 32),
        ),
        child: OutlinedButton(
          onPressed: () => _tooltip.currentState?.ensureTooltipVisible(),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            minimumSize: const Size(64, 72),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                WorkshopVectorIcon(item.kind, size: 48),
                if (widget.showName) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (item.caption.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(item.caption, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
