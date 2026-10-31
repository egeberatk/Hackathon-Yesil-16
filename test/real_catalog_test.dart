import 'dart:convert';

import 'package:hackathon_projesi/core/guide_language.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hackathon_projesi/models/material_item.dart';
import 'package:hackathon_projesi/models/upcycling_project.dart';
import 'package:hackathon_projesi/screens/photo_preview_screen.dart';
import 'package:hackathon_projesi/services/analysis_service.dart';
import 'package:hackathon_projesi/services/recipe_matching_service.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';
import 'package:hackathon_projesi/widgets/project_card.dart';
import 'package:hackathon_projesi/widgets/recipe_icon_grid.dart';

const approvedIds = {
  'project_49',
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
};

final originalIds = approvedIds
    .where((id) => int.parse(id.split('_').last) < 40)
    .toSet();

class CatalogBundle extends CachingAssetBundle {
  CatalogBundle(this.source);
  final String source;
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(source);
  @override
  Future<ByteData> load(String key) => throw UnsupportedError(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String source;
  late List<UpcyclingProject> catalog;
  setUpAll(() async {
    source = await rootBundle.loadString(RecipeRepository.assetPath);
    catalog = await RecipeRepository(bundle: CatalogBundle(source)).load();
  });

  test('Gerçek asset tam 17 onaylı kaydı tüm alanlarıyla yükler', () {
    final json = jsonDecode(source) as Map<String, dynamic>;
    expect(json['approved_ids'], hasLength(17));
    expect((json['approved_ids'] as List).toSet(), approvedIds);
    expect(json['projects'], hasLength(17));
    expect(catalog, hasLength(17));
    expect(catalog.map((project) => project.id).toSet(), approvedIds);
    for (final project in catalog) {
      expect(project.name, isNotEmpty);
      expect(project.description, isNotEmpty);
      expect(project.steps, isNotEmpty);
      expect(project.practicalUse, isNotEmpty);
      expect(project.safetyWarning, isNotEmpty);
      expect(project.imagePrompt, isNotEmpty);
    }
  });

  test('Tüm gerçek tarif material_id değerleri Flutter tarafından tanınır', () {
    for (final project in catalog) {
      for (final material in project.requiredMaterials) {
        expect(
          WasteType.fromId(material.materialId),
          isNot(WasteType.unknown),
          reason: '${project.id}: ${material.materialId}',
        );
      }
    }
    for (final id in ['project_38', 'project_39']) {
      final project = catalog.singleWhere((p) => p.id == id);
      expect(project.requiredMaterials.single.materialId, 'yogurt_container');
      expect(project.requiredMaterials.single.quantity, 1);
    }
  });

  test(
    'Yeni dokuz tarifin içeriği ve gerçekçi adet gereksinimleri korunur',
    () {
      final expected = <String, Map<String, int>>{
        'project_40': {'pet_bottle': 1, 'plastic_cap': 1},
        'project_41': {'pet_bottle': 1, 'plastic_cap': 1},
        'project_42': {'pet_bottle': 1},
        'project_43': {'yogurt_container': 1},
        'project_44': {'yogurt_container': 1},
        'project_45': {'cardboard_box': 3},
        'project_46': {'cardboard_box': 1},
        'project_47': {'glass_jar': 1, 'clean_paper': 1},
        'project_48': {'egg_carton': 1, 'yogurt_container': 2},
      };
      for (final entry in expected.entries) {
        final project = catalog.singleWhere((p) => p.id == entry.key);
        expect({
          for (final material in project.requiredMaterials)
            material.materialId: material.quantity,
        }, entry.value);
        expect(project.requiredSupplies, isNotEmpty);
        expect(project.optionalSupplies, isNotEmpty);
        expect(project.estimatedMinutes, greaterThan(0));
        expect(project.steps.length, greaterThanOrEqualTo(4));
        final inventory = entry.value.entries
            .map(
              (item) => MaterialItem(
                type: WasteType.fromId(item.key),
                quantity: item.value,
              ),
            )
            .toList();
        expect(
          RecipeMatchingService.match([project], inventory).single.canMake,
          isTrue,
        );
        expect(
          RecipeMatchingService.match([project], []).single.canMake,
          isFalse,
        );
        for (final materialId in entry.value.keys) {
          final incomplete = inventory
              .where((item) => item.type.materialId != materialId)
              .toList();
          expect(
            RecipeMatchingService.match([project], incomplete).single.canMake,
            isFalse,
            reason: '${project.id}: $materialId yokken önerilmemeli',
          );
        }
      }
    },
  );

  test('Kapaksız PET, eksik karton ve yetersiz hazine kabı uygun sayılmaz', () {
    final pet = RecipeMatchingService.match(catalog, [
      MaterialItem(type: WasteType.plastic),
    ]);
    expect(
      pet.singleWhere((m) => m.project.id == 'project_42').canMake,
      isTrue,
    );
    for (final id in ['project_40', 'project_41']) {
      final missing = pet
          .singleWhere((m) => m.project.id == id)
          .missingMaterials
          .single;
      expect(missing.materialId, 'plastic_cap');
      expect(missing.quantity, 1);
    }
    final cardboard = RecipeMatchingService.match(catalog, [
      MaterialItem(type: WasteType.cardboard),
    ]);
    expect(
      cardboard.singleWhere((m) => m.project.id == 'project_46').canMake,
      isTrue,
    );
    expect(
      cardboard.singleWhere((m) => m.project.id == 'project_45').totalMissing,
      2,
    );
    final mancala = catalog.singleWhere((p) => p.id == 'project_48');
    final partial = RecipeMatchingService.match(
      [mancala],
      [
        MaterialItem(type: WasteType.eggCarton),
        MaterialItem(type: WasteType.yogurtContainer),
      ],
    ).single;
    expect(partial.canMake, isFalse);
    expect(partial.missingMaterials.single.materialId, 'yogurt_container');
    expect(partial.totalMissing, 1);
    final complete = RecipeMatchingService.match(
      [mancala],
      [
        MaterialItem(type: WasteType.eggCarton),
        MaterialItem(type: WasteType.yogurtContainer),
        MaterialItem(type: WasteType.yogurtContainer),
      ],
    ).single;
    expect(complete.canMake, isTrue);
  });

  test('Bir onaylı yoğurt kabıyla gerçek 38 ve 39 tarifleri yapılabilir', () {
    final matches = RecipeMatchingService.match(catalog, [
      MaterialItem(type: WasteType.yogurtContainer),
    ]);
    expect(matches.where((m) => m.canMake).map((m) => m.project.id), [
      'project_38',
      'project_39',
      'project_43',
      'project_44',
    ]);
    final pending = RecipeMatchingService.match(catalog, [
      MaterialItem(type: WasteType.yogurtContainer, requiresConfirmation: true),
    ]);
    for (final id in ['project_38', 'project_39']) {
      expect(pending.singleWhere((m) => m.project.id == id).totalMissing, 1);
    }
  });

  test(
    'Gerçek katalogda adet toplamı, eksik miktarlar ve tam sıralama doğru',
    () {
      final matches = RecipeMatchingService.match(catalog, [
        MaterialItem(type: WasteType.cardboardRoll),
        MaterialItem(type: WasteType.cardboardRoll),
        MaterialItem(type: WasteType.cardboard),
        MaterialItem(type: WasteType.cleanPaper),
        MaterialItem(type: WasteType.plasticCap, quantity: 8),
        MaterialItem(type: WasteType.plastic, quantity: 4),
        MaterialItem(
          type: WasteType.yogurtContainer,
          requiresConfirmation: true,
        ),
        MaterialItem(type: WasteType.unknown, quantity: 99),
      ]);
      expect(
        matches
            .where((m) => originalIds.contains(m.project.id))
            .map((m) => m.project.id),
        [
          'project_26',
          'project_01',
          'project_38',
          'project_39',
          'project_03',
          'project_15',
          'project_19',
        ],
      );
      expect(
        matches
            .where((m) => originalIds.contains(m.project.id))
            .take(1)
            .every((m) => m.canMake),
        isTrue,
      );
      expect(
        matches
            .singleWhere((m) => m.project.id == 'project_01')
            .missingMaterials
            .single
            .quantity,
        1,
      );
      final mancala = matches.singleWhere((m) => m.project.id == 'project_48');
      expect(
        {
          for (final item in mancala.missingMaterials)
            item.materialId: item.quantity,
        },
        {'egg_carton': 1, 'yogurt_container': 2},
      );
      expect(mancala.totalMissing, 3);
    },
  );

  test(
    'Gerçek katalogda boş envanter tüm 17 yakın tarifi ve eksikleri korur',
    () {
      final matches = RecipeMatchingService.match(catalog, []);
      expect(matches, hasLength(17));
      expect(matches.every((m) => !m.canMake), isTrue);
      expect(
        matches
            .where((m) => originalIds.contains(m.project.id))
            .map((m) => m.project.id),
        [
          'project_38',
          'project_39',
          'project_15',
          'project_26',
          'project_01',
          'project_03',
          'project_19',
        ],
      );
    },
  );

  testWidgets(
    'Gerçek katalog: fotoğraf analizi → onay → 17 tarif → Örgü İpi Kasesi detayı',
    (tester) async {
      final service = AnalysisService(
        baseUrl: 'https://backend.test',
        clientFactory: () => MockClient((request) async {
          expect(request.url.path, '/analyze');
          expect(
            request.headers['content-type'],
            contains('multipart/form-data'),
          );
          return http.Response(
            jsonEncode({
              'materials': [
                {
                  'name': 'Yoğurt kabı',
                  'material_id': 'yogurt_container',
                  'quantity': 1,
                  'confidence': 'uncertain',
                  'requires_confirmation': true,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final photo = XFile.fromData(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
        ),
        name: 'photo.png',
      );
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: CatalogBundle(source),
          child: MaterialApp(
            home: PhotoPreviewScreen(photo: photo, analysisService: service),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Analiz Et'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Analiz Et'));
      await tester.pumpAndSettle();
      expect(find.text('Malzemelerini Doğrula'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Projeleri Keşfet'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.byTooltip('Malzemeyi düzenle'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Malzemeyi düzenle'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Kaydet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Projeleri Keşfet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Projeleri Keşfet'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('project-card-project_38')),
        300,
      );
      final cards = tester
          .widgetList<ProjectCard>(find.byType(ProjectCard))
          .toList();
      expect(cards.length, lessThan(21));
      expect(cards.first.project.id, 'project_38');
      expect(cards.first.match!.canMake, isTrue);
      await tester.ensureVisible(find.text('Örgü İpi Kasesi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Örgü İpi Kasesi'));
      await tester.pumpAndSettle();
      expect(find.text('Örgü İpi Kasesi'), findsOneWidget);
      final material = tester.widget<RecipeIconTile>(
        find
            .descendant(
              of: find.byKey(const Key('required-material-icons')),
              matching: find.byType(RecipeIconTile),
            )
            .first,
      );
      expect(material.item.id, 'yogurt_container');
      expect(material.item.caption, '1 adet');
      await tester.tap(find.byTooltip('Güvenlik uyarısı'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          GuideLanguage.neutral(
            catalog.singleWhere((p) => p.id == 'project_38').safetyWarning,
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
