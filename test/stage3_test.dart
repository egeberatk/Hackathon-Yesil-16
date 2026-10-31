import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hackathon_projesi/core/app_theme.dart';
import 'package:hackathon_projesi/models/material_item.dart';
import 'package:hackathon_projesi/models/upcycling_project.dart';
import 'package:hackathon_projesi/screens/home_screen.dart';
import 'package:hackathon_projesi/screens/projects_screen.dart';
import 'package:hackathon_projesi/screens/project_detail_screen.dart';
import 'package:hackathon_projesi/services/photo_service.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';
import 'package:hackathon_projesi/services/recipe_matching_service.dart';
import 'package:hackathon_projesi/widgets/project_card.dart';
import 'package:hackathon_projesi/widgets/recipe_step_card.dart';
import 'package:hackathon_projesi/widgets/recipe_step_viewer.dart';
import 'package:hackathon_projesi/widgets/recipe_motion_player.dart';
import 'package:hackathon_projesi/animations/pet_planter_steps.dart';
import 'package:hackathon_projesi/widgets/recipe_icon_grid.dart';

class CatalogAssets extends CachingAssetBundle {
  CatalogAssets(this.source);
  final String source;
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(source);
  @override
  Future<ByteData> load(String key) => throw UnsupportedError(key);
}

class QuietPhotos extends PhotoService {
  @override
  Future<XFile?> recover() async => null;
  @override
  Future<XFile?> pick(ImageSource source) async => null;
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
    Widget screen, {
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
        bundle: CatalogAssets(source),
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: screen,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    final element = finder.evaluate().single;
    final target = element.widget is ProjectCard
        ? find.descendant(
            of: finder,
            matching: find.text((element.widget as ProjectCard).project.name),
          )
        : finder;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<Set<String>> visitCatalog(WidgetTester tester) async {
    final seen = <String>{};
    for (var i = 0; i < 100 && seen.length < catalog.length; i++) {
      seen.addAll(
        tester
            .widgetList<ProjectCard>(find.byType(ProjectCard))
            .map((card) => card.project.id),
      );
      if (seen.length == catalog.length) break;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
      await tester.pumpAndSettle();
    }
    return seen;
  }

  testWidgets(
    '21 katalog kaydı tembel listeden erişilir, detay ve alt navigasyon korunur',
    (tester) async {
      await app(tester, HomeScreen(photoService: QuietPhotos()));
      await tap(tester, find.widgetWithText(NavigationDestination, 'Projeler'));
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(ProjectCard).evaluate().length, lessThan(21));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('project-card-project_01')),
        300,
      );
      final first = find.byKey(const ValueKey('project-card-project_01'));
      expect(
        find.descendant(of: first, matching: find.text('3 × Karton rulo')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: first, matching: find.text('1 × Karton kutu')),
        findsOneWidget,
      );
      expect(
        await visitCatalog(tester),
        catalog.map((project) => project.id).toSet(),
      );
      final last = find.byKey(const ValueKey('project-card-project_48'));
      await tester.scrollUntilVisible(last, 300);
      await tap(tester, last);
      expect(
        tester
            .widget<ProjectDetailScreen>(find.byType(ProjectDetailScreen))
            .project
            .id,
        'project_48',
      );
      await tap(tester, find.byType(BackButton));
      expect(
        find.text('Yumurta Kolisinden Mangala Oyunu').hitTestable(),
        findsOneWidget,
      );
      await tap(tester, find.widgetWithText(NavigationDestination, 'Tara'));
      expect(find.byType(BottomSheet), findsNothing);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await tap(
        tester,
        find.widgetWithText(NavigationDestination, 'Ana Sayfa'),
      );
      expect(find.text('Atığını Tara'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Gerçek eşleşmeler ve eksik adetler kartta ve detayda aynı kalır',
    (tester) async {
      final items = [
        MaterialItem(type: WasteType.yogurtContainer),
        MaterialItem(
          type: WasteType.glass,
          quantity: 2,
          requiresConfirmation: true,
        ),
        MaterialItem(type: WasteType.unknown),
      ];
      final expected = RecipeMatchingService.match(catalog, items);
      await app(tester, ProjectsScreen(items: items));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('project-card-project_38')),
        300,
      );
      final ready = tester.widget<ProjectCard>(
        find.byKey(const ValueKey('project-card-project_38')),
      );
      expect(ready.match!.canMake, isTrue);
      expect(ready.project.id, expected.first.project.id);
      final missing = find.byKey(const ValueKey('project-card-project_48'));
      await tester.scrollUntilVisible(missing, 500, maxScrolls: 70);
      final card = tester.widget<ProjectCard>(missing);
      expect(card.match!.canMake, isFalse);
      expect(
        {
          for (final material in card.match!.missingMaterials)
            material.materialId: material.quantity,
        },
        {'egg_carton': 1, 'yogurt_container': 1},
      );
      for (final material in card.match!.missingMaterials) {
        expect(
          find.descendant(
            of: missing,
            matching: find.text(
              '${material.name}: ${material.quantity} adet eksik',
            ),
          ),
          findsOneWidget,
        );
      }
      await tap(tester, missing);
      final missingTiles = tester.widgetList<RecipeIconTile>(
        find.descendant(
          of: find.byKey(const Key('missing-material-icons')),
          matching: find.byType(RecipeIconTile),
        ),
      );
      for (final material in card.match!.missingMaterials) {
        final tile = missingTiles.singleWhere(
          (tile) => tile.item.id == material.materialId,
        );
        expect(tile.item.name, material.name);
        expect(tile.item.caption, '${material.quantity} eksik');
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Tarif adımları JSON metinleriyle ileri geri gezinir ve sınırda durur',
    (tester) async {
      final project = catalog.singleWhere(
        (project) => project.id == 'project_40',
      );
      await app(tester, ProjectDetailScreen(project: project));
      await tap(tester, find.byKey(const Key('start-building')));
      await tester.scrollUntilVisible(find.byType(RecipeStepCard), 400);
      expect(
        tester.widget<RecipeStepCard>(find.byType(RecipeStepCard)).text,
        project.steps.first,
      );
      expect(
        tester.widget<RecipeStepCard>(find.byType(RecipeStepCard)).media,
        isA<RecipeMotionPlayer>(),
      );
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('previous-step')))
            .onPressed,
        isNull,
      );
      for (var step = 1; step < project.steps.length; step++) {
        await tap(tester, find.byKey(const Key('next-step')));
        final card = tester.widget<RecipeStepCard>(find.byType(RecipeStepCard));
        expect(card.number, step + 1);
        expect(card.total, project.steps.length);
        expect(card.text, project.steps[step]);
        expect(
          find.text(PetPlanterSteps.steps[step].description),
          findsOneWidget,
        );
      }
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('next-step')))
            .onPressed,
        isNotNull,
      );
      expect(find.text('Bitir'), findsOneWidget);
      for (var step = project.steps.length - 2; step >= 0; step--) {
        await tap(tester, find.byKey(const Key('previous-step')));
        expect(
          tester.widget<RecipeStepCard>(find.byType(RecipeStepCard)).text,
          project.steps[step],
        );
      }
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('previous-step')))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Tek adımlı metin görünümü ve gelecekteki isteğe bağlı medya alanı çalışır',
    (tester) async {
      final original = catalog.first;
      final project = UpcyclingProject(
        id: original.id,
        name: original.name,
        description: original.description,
        requiredMaterials: original.requiredMaterials,
        requiredSupplies: original.requiredSupplies,
        optionalSupplies: original.optionalSupplies,
        category: original.category,
        difficulty: original.difficulty,
        estimatedMinutes: original.estimatedMinutes,
        steps: [original.steps.first],
        practicalUse: original.practicalUse,
        safetyWarning: original.safetyWarning,
        imagePrompt: original.imagePrompt,
      );
      await app(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: RecipeStepViewer(
              project: project,
              mediaBuilder: (context, value, index) {
                expect(value, same(project));
                expect(index, 0);
                return const SizedBox(
                  key: Key('future-step-media'),
                  height: 80,
                  child: Icon(Icons.eco_outlined),
                );
              },
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('future-step-media')), findsOneWidget);
      expect(find.text(original.steps.first), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('previous-step')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('next-step')))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final config in [
    (const Size(320, 640), 2.0),
    (const Size(640, 360), 1.5),
  ]) {
    testWidgets(
      'Tarif listesi, detay ve adımlar ${config.$1} metin ${config.$2} taşmaz',
      (tester) async {
        await app(
          tester,
          ProjectsScreen(
            items: [MaterialItem(type: WasteType.yogurtContainer)],
          ),
          size: config.$1,
          scale: config.$2,
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('project-card-project_38')),
          350,
        );
        await tap(
          tester,
          find.byKey(const ValueKey('project-card-project_38')),
        );
        await tap(tester, find.byKey(const Key('start-building')));
        await tester.scrollUntilVisible(
          find.byKey(const Key('next-step')),
          350,
        );
        await tap(tester, find.byKey(const Key('next-step')));
        expect(
          tester.widget<RecipeStepCard>(find.byType(RecipeStepCard)).number,
          2,
        );
        await tap(tester, find.byKey(const Key('previous-step')));
        expect(
          tester.widget<RecipeStepCard>(find.byType(RecipeStepCard)).number,
          1,
        );
        await tap(tester, find.byType(BackButton));
        await tap(tester, find.byTooltip('Güvenlik uyarısı'));
        expect(find.textContaining('keskin plastik'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('İsteğe bağlı üçüncü aşama ekran önizlemeleri', (tester) async {
    if (!const bool.fromEnvironment('STAGE3_PREVIEW')) return;
    Future<void> capture(GlobalKey key, String name) async {
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('.dart_tool/design-preview/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    var key = GlobalKey();
    await app(tester, HomeScreen(photoService: QuietPhotos()), boundary: key);
    await tap(tester, find.widgetWithText(NavigationDestination, 'Projeler'));
    await capture(key, 'catalog-stage3');
    key = GlobalKey();
    await app(
      tester,
      ProjectsScreen(items: [MaterialItem(type: WasteType.yogurtContainer)]),
      boundary: key,
    );
    await capture(key, 'matches-stage3');
    key = GlobalKey();
    final project = catalog.singleWhere(
      (project) => project.id == 'project_40',
    );
    await app(tester, ProjectDetailScreen(project: project), boundary: key);
    await capture(key, 'recipe-detail');
    await tap(tester, find.byKey(const Key('start-building')));
    await tester.scrollUntilVisible(find.byType(RecipeStepCard), 350);
    await tap(tester, find.byKey(const Key('next-step')));
    await capture(key, 'recipe-step');
  });
}
