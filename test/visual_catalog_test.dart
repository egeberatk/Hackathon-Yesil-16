import 'dart:io';

import 'package:hackathon_projesi/core/guide_language.dart';

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_projesi/animations/workshop_steps.dart';
import 'package:hackathon_projesi/core/app_theme.dart';
import 'package:hackathon_projesi/models/upcycling_project.dart';
import 'package:hackathon_projesi/screens/pet_project_detail_screen.dart';
import 'package:hackathon_projesi/screens/project_detail_screen.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';
import 'package:hackathon_projesi/widgets/recipe_detail_layout.dart';
import 'package:hackathon_projesi/widgets/recipe_icon_grid.dart';
import 'package:hackathon_projesi/widgets/recipe_motion_player.dart';
import 'package:hackathon_projesi/widgets/recipe_project_preview.dart';
import 'package:hackathon_projesi/widgets/recipe_step_card.dart';
import 'package:hackathon_projesi/widgets/workshop_vector_icon.dart';

class _Catalog extends CachingAssetBundle {
  _Catalog(this.source);
  final String source;
  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(source);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String source;
  late List<UpcyclingProject> catalog;
  setUpAll(() async {
    source = await rootBundle.loadString(RecipeRepository.assetPath);
    catalog = RecipeRepository.parse(source);
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  Future<void> app(
    WidgetTester tester,
    Widget home, {
    Size size = const Size(390, 844),
    double scale = 1,
    GlobalKey? boundary,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _Catalog(source),
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: home,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  List<RecipeIconTile> tiles(WidgetTester tester, String key) => tester
      .widgetList<RecipeIconTile>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(RecipeIconTile),
        ),
      )
      .toList();
  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('.dart_tool/visual-catalog/previews/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  test('Supply icons represent real items and preserve data quantities/alternatives', () {
    final bowling = catalog.singleWhere((p) => p.id == 'project_15');
    expect(
      RecipeVisualItem.supplies(bowling.requiredSupplies).single.kind,
      WorkshopIconKind.ball,
    );
    expect(
      RecipeVisualItem.supplies(bowling.optionalSupplies).single.kind,
      WorkshopIconKind.water,
    );
    final drum = RecipeVisualItem.supplies(
      catalog.singleWhere((p) => p.id == 'project_39').requiredSupplies,
    );
    expect(
      drum.singleWhere((p) => p.kind == WorkshopIconKind.pencil).caption,
      '2 adet',
    );
    final mangala = RecipeVisualItem.supplies(
      catalog.singleWhere((p) => p.id == 'project_48').requiredSupplies,
    );
    expect(
      mangala.singleWhere((p) => p.kind == WorkshopIconKind.stone).caption,
      '48 adet',
    );
    expect(
      mangala.map((p) => p.kind),
      containsAll([WorkshopIconKind.soap, WorkshopIconKind.water]),
    );
    final catTools = RecipeVisualItem.supplies(
      catalog.singleWhere((p) => p.id == 'project_45').requiredSupplies,
    );
    expect(
      catTools
          .singleWhere((p) => p.kind == WorkshopIconKind.scissors)
          .displayName,
      'Makas / bıçak',
    );
    expect(catTools.any((p) => p.kind == WorkshopIconKind.knife), isFalse);
    final basketTools = RecipeVisualItem.supplies(
      catalog.singleWhere((p) => p.id == 'project_43').requiredSupplies,
    );
    expect(
      basketTools.singleWhere((p) => p.kind == WorkshopIconKind.cord).caption,
      '3 × 60 cm',
    );
    for (final p in catalog) {
      for (final source in [...p.requiredSupplies, ...p.optionalSupplies]) {
        final items = RecipeVisualItem.supplies([source]);
        expect(items, isNotEmpty);
        expect(
          items.every((item) => item.kind != WorkshopIconKind.other),
          isTrue,
          reason: '${p.id}: $source',
        );
        expect(
          items.every(
            (item) => item.name.contains(GuideLanguage.neutral(source)),
          ),
          isTrue,
        );
        expect(items.every((item) => !item.displayName.contains('?')), isTrue);
      }
    }
  });

  const ids = [
    'project_01',
    'project_03',
    'project_15',
    'project_19',
    'project_26',
    'project_38',
    'project_39',
    'project_40',
    'project_41',
    'project_42',
    'project_43',
    'project_44',
    'project_45',
    'project_46',
    'project_47',
    'project_48',
    'project_49',
  ];
  for (final id in ids) {
    testWidgets(
      '$id uses the shared overview, real quantities and pinned Start',
      (tester) async {
        final p = catalog.singleWhere((p) => p.id == id);
        await app(tester, ProjectDetailScreen(project: p));
        expect(find.byType(RecipeDetailLayout), findsOneWidget);
        expect(find.text(p.name), findsOneWidget);
        expect(find.text(p.category), findsOneWidget);
        expect(find.text('${p.estimatedMinutes} dakika'), findsOneWidget);
        expect(find.text(p.difficulty), findsOneWidget);
        expect(
          find.byKey(const Key('finished-project-preview')),
          findsOneWidget,
        );
        expect(find.byType(RecipeMotionPlayer), findsNothing);
        final materialTiles = tiles(tester, 'required-material-icons');
        expect(materialTiles.length, p.requiredMaterials.length);
        for (var i = 0; i < materialTiles.length; i++) {
          expect(materialTiles[i].item.id, p.requiredMaterials[i].materialId);
          expect(
            materialTiles[i].item.name,
            startsWith(p.requiredMaterials[i].name),
          );
          expect(
            materialTiles[i].item.caption,
            '${p.requiredMaterials[i].quantity} adet',
          );
          expect(materialTiles[i].showName, isTrue);
        }
        final start = find.byKey(const Key('start-building'));
        final before = tester.getRect(start);
        expect(before.height, greaterThanOrEqualTo(56));
        expect(before.bottom, lessThanOrEqualTo(844));
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -450),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(start), before);
        if (p.optionalSupplies.isNotEmpty) {
          expect(
            find.byKey(const Key('optional-supply-icons')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'All 17 Start buttons open original ordered steps and Back restores overview',
    (tester) async {
      for (final p in catalog) {
        await app(tester, ProjectDetailScreen(project: p));
        await press(tester, find.byKey(const Key('start-building')));
        for (var i = 0; i < p.steps.length; i++) {
          final card = tester.widget<RecipeStepCard>(
            find.byType(RecipeStepCard),
          );
          expect(card.number, i + 1);
          expect(card.total, p.steps.length);
          expect(card.text, p.steps[i]);
          if (i < p.steps.length - 1) {
            await press(tester, find.byKey(const Key('next-step')));
          }
        }
        expect(find.text('Bitir'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('next-step')))
              .onPressed,
          isNotNull,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(RecipeDetailLayout), findsOneWidget);
        expect(find.byKey(const Key('start-building')), findsOneWidget);
        if (p.id == 'project_40') {
          expect(find.byType(PetProjectDetailScreen), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
      expect(RecipeProjectPreview.staticIds.length, 6);
      expect(WorkshopSteps.recipes.length, 16);
    },
  );

  testWidgets(
    'Full safety is available on tap; details are collapsed by default',
    (tester) async {
      final p = catalog.singleWhere((p) => p.id == 'project_44');
      await app(tester, ProjectDetailScreen(project: p));
      expect(find.text(GuideLanguage.neutral(p.safetyWarning)), findsNothing);
      expect(find.text(p.practicalUse), findsNothing);
      await press(tester, find.byTooltip('Güvenlik uyarısı'));
      expect(find.text(GuideLanguage.neutral(p.safetyWarning)), findsOneWidget);
      await press(tester, find.text('Kapat'));
      await press(tester, find.byKey(const Key('recipe-extra-info')));
      expect(find.text(p.practicalUse), findsOneWidget);
    },
  );

  for (final config in [
    (const Size(320, 640), 2.0),
    (const Size(640, 360), 1.5),
  ]) {
    testWidgets(
      'All 17 visual overviews and tooltips fit ${config.$1} text ${config.$2}',
      (tester) async {
        for (final p in catalog) {
          await app(
            tester,
            ProjectDetailScreen(key: ValueKey(p.id), project: p),
            size: config.$1,
            scale: config.$2,
          );
          final start = find.byKey(const Key('start-building'));
          expect(start.hitTestable(), findsOneWidget);
          final first = find
              .descendant(
                of: find.byKey(const Key('required-material-icons')),
                matching: find.byType(RecipeIconTile),
              )
              .first;
          await press(tester, first);
          expect(tester.takeException(), isNull);
          await tester.pump(const Duration(seconds: 6));
          await tester.pumpAndSettle();
          await press(tester, find.byKey(const Key('recipe-extra-info')));
          expect(tester.takeException(), isNull);
          await press(tester, find.byTooltip('Güvenlik uyarısı'));
          expect(tester.takeException(), isNull);
          await press(tester, find.text('Kapat'));
          await tester.pumpWidget(const SizedBox());
        }
      },
    );
  }

  testWidgets('Optional real Flutter detail screenshots', (tester) async {
    if (!const bool.fromEnvironment('VISUAL_CATALOG_PREVIEW')) return;
    for (final p in catalog) {
      final key = GlobalKey();
      await app(tester, ProjectDetailScreen(project: p), boundary: key);
      await capture(tester, key, p.id);
      if ({
        'project_15',
        'project_19',
        'project_44',
        'project_40',
      }.contains(p.id)) {
        await tester.ensureVisible(
          find.byKey(const Key('required-material-icons')),
        );
        await tester.pumpAndSettle();
        await capture(tester, key, '${p.id}-materials');
      }
      await tester.pumpWidget(const SizedBox());
    }
  });
}
