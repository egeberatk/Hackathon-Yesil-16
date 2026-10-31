import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hackathon_projesi/animations/pet_planter_steps.dart';
import 'package:hackathon_projesi/animations/workshop_steps.dart';
import 'package:hackathon_projesi/core/app_theme.dart';
import 'package:hackathon_projesi/models/material_item.dart';
import 'package:hackathon_projesi/models/upcycling_project.dart';
import 'package:hackathon_projesi/screens/photo_preview_screen.dart';
import 'package:hackathon_projesi/screens/material_confirmation_screen.dart';
import 'package:hackathon_projesi/screens/project_detail_screen.dart';
import 'package:hackathon_projesi/services/analysis_service.dart';
import 'package:hackathon_projesi/services/material_candidate_filter.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';
import 'package:hackathon_projesi/services/recipe_photo_repository.dart';
import 'package:hackathon_projesi/services/recipe_matching_service.dart';
import 'package:hackathon_projesi/widgets/material_card.dart';
import 'package:hackathon_projesi/widgets/recipe_step_card.dart';
import 'package:hackathon_projesi/widgets/recipe_motion_player.dart';
import 'package:hackathon_projesi/widgets/recipe_product_photo.dart';

class _Assets extends CachingAssetBundle {
  _Assets(
    this.catalog, {
    this.manifest = '{"version":1,"photos":{}}',
    this.image,
  });
  final String catalog, manifest;
  final Uint8List? image;
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(
        key == RecipePhotoRepository.assetPath ? manifest : catalog,
      );
  @override
  Future<ByteData> load(String key) {
    if (key.startsWith('assets/recipe_photos/') && key.endsWith('.png')) {
      if (image == null) return Future.error(StateError('missing asset'));
      return SynchronousFuture(ByteData.sublistView(image!));
    }
    return rootBundle.load(key);
  }
}

class _Analysis extends AnalysisService {
  _Analysis(this.items);
  final List<MaterialItem> items;
  @override
  Future<List<MaterialItem>> analyze(XFile photo) async => items;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String source;
  late List<UpcyclingProject> catalog;
  late Uint8List pixel;
  setUpAll(() async {
    source = await rootBundle.loadString(RecipeRepository.assetPath);
    catalog = RecipeRepository.parse(source);
    pixel = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAGCAIAAABxZ0isAAAAFElEQVR4nGM0aopiwAaYsIrSSQIAoAoBGsahb8wAAAAASUVORK5CYII=',
    );
  });
  Future<void> app(
    WidgetTester tester,
    Widget child, {
    AssetBundle? bundle,
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: bundle ?? _Assets(source),
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
          home: child,
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

  final cases = jsonDecode(
    File('test/fixtures/material_label_cases.json').readAsStringSync(),
  ) as List;
  for (final c in cases) {
    test('Shared label: ${c['name']}', () {
      expect(MaterialCandidateFilter.isPaperCup(c['name']), c['paper']);
      expect(MaterialCandidateFilter.isElectronic(c['name']), c['electronic']);
    });
  }
  test('Selection keeps raw evidence and rescues paper cups without forcing other materials', () {
    final raw = [
      MaterialItem(type: WasteType.cardboard, name: 'Kulaklık'),
      MaterialItem(
        type: WasteType.cardboardRoll,
        name: 'Karton kahve bardağı',
        quantity: 2,
      ),
    ];
    final selected = MaterialCandidateFilter.select(raw, catalog);
    expect(raw[1].type, WasteType.cardboardRoll);
    expect(selected.candidates.single.type, WasteType.paperCup);
    expect(selected.candidates.single.quantity, 2);
    expect(selected.candidates.single.requiresConfirmation, isTrue);
    expect(selected.excluded.single.reason, 'electronic');
    final excluded = MaterialCandidateFilter.select([
      MaterialItem(type: WasteType.cardboardRoll, name: 'Plastik bardak'),
      MaterialItem(type: WasteType.unknown, name: 'Ahşap parça'),
    ], catalog);
    expect(excluded.candidates, isEmpty);
    expect(excluded.explanation, isNotNull);
    final packaging = MaterialCandidateFilter.select([
      MaterialItem(type: WasteType.cardboard, name: 'Telefonun karton kutusu'),
    ], catalog);
    expect(packaging.candidates.single.type, WasteType.cardboard);
    final noRecipe = MaterialCandidateFilter.select([
      MaterialItem(type: WasteType.paperCup),
    ], catalog.where((p) => p.id != 'project_49').toList());
    expect(noRecipe.excluded.single.reason, 'no_catalog_material');
  });
  test(
    'New recipe has one paper cup, four steps and confirmed matching only',
    () {
      expect(catalog.length, 17);
      final p = catalog.singleWhere((p) => p.id == 'project_49');
      expect(p.steps.length, 4);
      expect(p.requiredMaterials.single.materialId, 'paper_cup');
      expect(p.requiredMaterials.single.quantity, 1);
      expect(WorkshopSteps.resolve(p, 3), isNotNull);
      var matches = RecipeMatchingService.match(catalog, [
        MaterialItem(type: WasteType.paperCup, requiresConfirmation: true),
      ]);
      expect(matches.every((m) => !m.canMake), isTrue);
      matches = RecipeMatchingService.match(catalog, [
        MaterialItem(type: WasteType.paperCup),
      ]);
      expect(matches.first.project.id, 'project_49');
      expect(matches.first.canMake, isTrue);
      expect(
        RecipeMatchingService.match(catalog, [])
            .singleWhere((m) => m.project.id == 'project_49')
            .missingMaterials
            .single
            .quantity,
        1,
      );
      for (final type in [
        WasteType.cardboardRoll,
        WasteType.cleanPaper,
        WasteType.plasticPackaging,
      ]) {
        expect(
          RecipeMatchingService.match(catalog, [
            MaterialItem(type: type),
          ]).singleWhere((m) => m.project.id == 'project_49').canMake,
          isFalse,
        );
      }
    },
  );
  testWidgets(
    'Headphones + paper cup: confirmation offers cup only; raw list stays intact',
    (tester) async {
      final items = [
        MaterialItem(type: WasteType.cardboard, name: 'Kulaklık'),
        MaterialItem(
          type: WasteType.unknown,
          name: 'Kâğıt bardak',
          quantity: 2,
        ),
      ];
      await app(
        tester,
        PhotoPreviewScreen(
          photo: XFile.fromData(pixel, name: 'test.png'),
          analysisService: _Analysis(items),
        ),
      );
      await press(tester, find.text('Analiz Et'));
      expect(find.byType(MaterialConfirmationScreen), findsOneWidget);
      final cards = tester.widgetList<MaterialCard>(find.byType(MaterialCard));
      expect(cards.length, 1);
      expect(cards.single.item.type, WasteType.paperCup);
      expect(cards.single.item.quantity, 2);
      expect(find.text('Kulaklık'), findsNothing);
      await press(tester, find.byKey(const Key('candidate-explanation')));
      expect(find.textContaining('önerilere alınmadı'), findsOneWidget);
      expect(items.length, 2);
      expect(items.last.type, WasteType.unknown);
    },
  );
  testWidgets(
    'No catalogue candidate explains the result and allows manual entry',
    (tester) async {
      await app(
        tester,
        PhotoPreviewScreen(
          photo: XFile.fromData(pixel, name: 'test.png'),
          analysisService: _Analysis([
            MaterialItem(type: WasteType.unknown, name: 'Kulaklık'),
          ]),
        ),
      );
      await press(tester, find.text('Analiz Et'));
      expect(find.byType(MaterialCard), findsNothing);
      expect(find.text('Kataloğa uygun malzeme bulunamadı.'), findsOneWidget);
      await press(tester, find.byKey(const Key('candidate-explanation')));
      expect(
        find.textContaining('uygun geri dönüşüm malzemesi bulunamadı'),
        findsOneWidget,
      );
      await press(tester, find.text('Kapat'));
      expect(find.text('Malzeme Ekle'), findsOneWidget);
    },
  );
  testWidgets(
    'All 17 guides have no repeated expansion, preserve risks and original counts',
    (tester) async {
      for (final p in catalog) {
        await app(tester, ProjectDetailScreen(project: p));
        await press(tester, find.byKey(const Key('start-building')));
        for (var i = 0; i < p.steps.length; i++) {
          expect(find.byType(ExpansionTile), findsNothing);
          final card = tester.widget<RecipeStepCard>(
            find.byType(RecipeStepCard),
          );
          expect(card.total, p.steps.length);
          expect(card.number, i + 1);
          expect(card.text, p.steps[i]);
          final texts = tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data ?? '')
              .join(' ')
              .toLowerCase();
          expect(texts, isNot(contains('yetişkin')), reason: '${p.id} step $i');
          final warning = p.id == 'project_40'
              ? PetPlanterSteps.resolve(p, i)!.warning
              : WorkshopSteps.resolve(p, i)!.warning;
          if (warning != null) expect(find.text(warning), findsOneWidget);
          if (i < p.steps.length - 1) {
            await press(tester, find.byKey(const Key('next-step')));
          }
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
  testWidgets('Paper cup guide finishes and removes its player', (
    tester,
  ) async {
    await app(
      tester,
      ProjectDetailScreen(
        project: catalog.singleWhere((p) => p.id == 'project_49'),
      ),
    );
    await press(tester, find.byKey(const Key('start-building')));
    for (var i = 0; i < 3; i++) {
      await press(tester, find.byKey(const Key('next-step')));
    }
    final player = tester.state(find.byType(RecipeMotionPlayer));
    await press(tester, find.byKey(const Key('next-step')));
    expect(player.mounted, isFalse);
    expect(find.text('Projen hazır!'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ProjectDetailScreen), findsOneWidget);
  });

  Map<String, dynamic> photoRecord() => {
    'asset': 'assets/recipe_photos/test.png',
    'title': 'Test photo',
    'author': 'Test author',
    'source_url': 'https://example.org/photo',
    'license': 'CC0-1.0',
    'license_url': 'https://creativecommons.org/publicdomain/zero/1.0/',
    'verified': true,
    'matches_recipe': true,
  };
  test('Photo manifest accepts only verified, matching, licensed assets', () {
    final record = photoRecord();
    expect(RecipePhoto.parse(record), isNotNull);
    expect(RecipePhoto.parse({...record, 'verified': false}), isNull);
    expect(RecipePhoto.parse({...record, 'matches_recipe': false}), isNull);
    expect(RecipePhoto.parse({...record, 'license': 'CC-BY-NC-2.0'}), isNull);
    expect(
      RecipePhoto.parse({...record, 'asset': 'https://example.org/random.jpg'}),
      isNull,
    );
    expect(
      RecipePhoto.parse({
        ...record,
        'asset': 'assets/recipe_photos/../secret.png',
      }),
      isNull,
    );
  });
  for (final state in ['missing', 'malformed', 'broken', 'success']) {
    testWidgets(
      'Product photo $state loads or keeps vector fallback without error',
      (tester) async {
        final manifest = state == 'malformed'
            ? 'invalid'
            : jsonEncode({
                'version': 1,
                'photos': state == 'missing'
                    ? {}
                    : {'project_49': photoRecord()},
              });
        final bundle = _Assets(
          source,
          manifest: manifest,
          image: state == 'success' ? pixel : null,
        );
        await app(
          tester,
          Scaffold(
            body: RecipeProductPhoto(
              projectId: 'project_49',
              fallback: const Text('Vektör önizleme'),
              repository: RecipePhotoRepository(bundle: bundle),
            ),
          ),
          bundle: bundle,
          size: const Size(320, 640),
          scale: 2,
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();
        if (state == 'success') {
          expect(find.byTooltip('Fotoğraf bilgisi'), findsOneWidget);
          expect(find.text('Vektör önizleme'), findsNothing);
          await press(tester, find.byTooltip('Fotoğraf bilgisi'));
          expect(find.textContaining('Test author'), findsOneWidget);
        } else {
          expect(find.text('Vektör önizleme'), findsOneWidget);
          expect(find.byTooltip('Fotoğraf bilgisi'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    testWidgets(
      'New cup detail, photo fallback and guide fit $size at large text',
      (tester) async {
        await app(
          tester,
          ProjectDetailScreen(
            project: catalog.singleWhere((p) => p.id == 'project_49'),
          ),
          size: size,
          scale: 2,
        );
        expect(find.byKey(const Key('product-photo-area')), findsOneWidget);
        await press(tester, find.byKey(const Key('start-building')));
        for (var i = 0; i < 4; i++) {
          await press(tester, find.byKey(const Key('next-step')));
          expect(tester.takeException(), isNull);
        }
        expect(find.text('Projen hazır!'), findsOneWidget);
      },
    );
  }
}
