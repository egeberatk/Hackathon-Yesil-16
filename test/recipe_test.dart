import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_projesi/models/material_item.dart';
import 'package:hackathon_projesi/models/upcycling_project.dart';
import 'package:hackathon_projesi/screens/projects_screen.dart';
import 'package:hackathon_projesi/services/recipe_matching_service.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';

// Test verileri onaylı tariflerin gerçek içeriklerini temsil etmez ve asset'e eklenmez.
Map<String, dynamic> record(String id, List<Map<String, dynamic>> materials) =>
    {
      'id': id,
      'name': 'Test tarifi $id',
      'description': 'Yalnızca test açıklaması',
      'required_materials': materials,
      'required_supplies': ['Test bandı'],
      'optional_supplies': ['Test boyası'],
      'category': 'Test kategorisi',
      'difficulty': 'Test zorluğu',
      'estimated_minutes': 7,
      'steps': ['Yalnızca test adımı'],
      'practical_use': 'Yalnızca test amacı',
      'safety_warning': 'Yalnızca test uyarısı',
      'image_prompt': 'Test görsel metni',
    };
Map<String, dynamic> need(String id, int count) => {
  'material_id': id,
  'name': 'Test malzemesi $id',
  'quantity': count,
};
UpcyclingProject project(String id, List<Map<String, dynamic>> materials) =>
    UpcyclingProject.fromJson(record(id, materials));

class MemoryRepository extends RecipeRepository {
  MemoryRepository(this.projects, {this.fail = false});
  final List<UpcyclingProject> projects;
  bool fail;
  @override
  Future<List<UpcyclingProject>> load() async {
    if (fail) throw const FormatException('Test yükleme hatası');
    return projects;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Asset yüklenir; onaysız tarif yüklenmez', () async {
    final catalog = await RecipeRepository().load();
    expect(
      catalog.every((project) => project.id.startsWith('project_')),
      isTrue,
    );
    final parsed = RecipeRepository.parse(
      jsonEncode({
        'approved_ids': ['project_01'],
        'projects': [
          record('project_01', [need('glass_jar', 1)]),
          {'id': 'project_99'},
        ],
      }),
    );
    expect(parsed.map((p) => p.id), ['project_01']);
  });

  test('Eksik alan, hatalı adet ve yinelenen tarif kimliği reddedilir', () {
    for (final invalid in [
      {
        ...record('project_01', [need('glass_jar', 1)]),
      }..remove('steps'),
      record('project_01', [need('glass_jar', 0)]),
    ]) {
      expect(() => UpcyclingProject.fromJson(invalid), throwsFormatException);
    }
    expect(
      () => RecipeRepository.parse(
        jsonEncode({
          'approved_ids': ['project_01'],
          'projects': [
            record('project_01', [need('glass_jar', 1)]),
            record('project_01', [need('glass_jar', 1)]),
          ],
        }),
      ),
      throwsFormatException,
    );
  });

  test('Aynı material_id miktarları toplanır; yardımcı malzemeler eşleşmeyi etkilemez', () {
    final match = RecipeMatchingService.match(
      [
        project('a', [need('glass_jar', 3)]),
      ],
      [
        MaterialItem(type: WasteType.glass),
        MaterialItem(type: WasteType.glass, quantity: 2),
      ],
    ).single;
    expect(match.canMake, isTrue);
    expect(match.totalMissing, 0);
  });

  test('Gerekli malzemede tekrarlanan türler de toplanır ve eksik miktar hesaplanır', () {
    final match = RecipeMatchingService.match(
      [
        project('a', [
          need('glass_jar', 2),
          need('glass_jar', 3),
          need('pet_bottle', 2),
        ]),
      ],
      [MaterialItem(type: WasteType.glass, quantity: 3)],
    ).single;
    expect(match.missingMaterials.map((m) => m.quantity), [2, 2]);
    expect(match.missingMaterials.map((m) => m.name), [
      'Test malzemesi glass_jar',
      'Test malzemesi pet_bottle',
    ]);
    expect(match.totalMissing, 4);
  });

  test('Unknown ve onaysız satırlar eşleştirmeye katılmaz', () {
    final match = RecipeMatchingService.match(
      [
        project('a', [need('glass_jar', 2)]),
      ],
      [
        MaterialItem(
          type: WasteType.glass,
          quantity: 10,
          requiresConfirmation: true,
        ),
        MaterialItem(type: WasteType.unknown, quantity: 10),
        MaterialItem(type: WasteType.glass),
      ],
    ).single;
    expect(match.missingMaterials.single.quantity, 1);
  });

  test('Fazla miktar negatif eksik üretmez; başka türe eşlemez', () {
    final match = RecipeMatchingService.match(
      [
        project('a', [need('glass_jar', 2), need('plastic_cap', 1)]),
      ],
      [
        MaterialItem(type: WasteType.glass, quantity: 100),
        MaterialItem(type: WasteType.plastic, quantity: 100),
      ],
    ).single;
    expect(match.missingMaterials.single.materialId, 'plastic_cap');
    expect(match.totalMissing, 1);
  });

  test('Sıra: tam eşleşme, eksik tür sayısı, eksik adet, eşitlikte kimlik', () {
    final matches = RecipeMatchingService.match(
      [
        project('two_types', [need('glass_jar', 1), need('pet_bottle', 1)]),
        project('one_type_many', [need('glass_jar', 8)]),
        project('one_type_few_b', [need('glass_jar', 2)]),
        project('one_type_few_a', [need('glass_jar', 2)]),
        project('ready', [need('metal_can', 1)]),
      ],
      [MaterialItem(type: WasteType.metal)],
    );
    expect(matches.map((m) => m.project.id), [
      'ready',
      'one_type_few_a',
      'one_type_few_b',
      'one_type_many',
      'two_types',
    ]);
    expect(matches.first.canMake, isTrue);
  });

  test('Hiç eşleşme yokken tüm tarifler en yakından başlayarak kalır', () {
    final matches = RecipeMatchingService.match([
      project('b', [need('glass_jar', 3)]),
      project('a', [need('glass_jar', 1)]),
    ], []);
    expect(matches.map((m) => m.project.id), ['a', 'b']);
    expect(matches.every((m) => !m.canMake), isTrue);
  });

  testWidgets('Bölümler, eksik miktar ve tarifin tüm detayları gösterilir', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectsScreen(
          items: [MaterialItem(type: WasteType.glass)],
          repository: MemoryRepository([
            project('ready', [need('glass_jar', 1)]),
            project('missing', [need('pet_bottle', 3)]),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Yapabilirsin'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('missing-section')),
      300,
    );
    expect(find.text('Eksik Malzemeli'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Test malzemesi pet_bottle: 3 adet eksik'),
      300,
    );
    await tester.ensureVisible(find.text('Test tarifi missing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test tarifi missing'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Yardımcı malzemeler'), 300);
    expect(find.text('•  Test bandı'), findsOneWidget);
    expect(find.text('•  Test boyası'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Güvenlik uyarısı'), 300);
    expect(find.text('Yalnızca test adımı'), findsOneWidget);
    expect(find.text('Yalnızca test amacı'), findsOneWidget);
    expect(find.text('Yalnızca test uyarısı'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tam eşleşme yokken en yakın tarifler ekranda kalır', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectsScreen(
          items: const [],
          repository: MemoryRepository([
            project('a', [need('glass_jar', 1)]),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Henüz tam eşleşen tarif yok.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('project-card-a')),
      300,
    );
    expect(find.text('Test tarifi a'), findsOneWidget);
  });

  testWidgets('Katalog yükleme hatası tekrar denenebilir', (tester) async {
    final repository = MemoryRepository([], fail: true);
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectsScreen(items: const [], repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Tarif kütüphanesi yüklenemedi.'),
      findsOneWidget,
    );
    repository.fail = false;
    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Onaylı tarif içerikleri henüz eklenmedi.'),
      findsOneWidget,
    );
  });
}
