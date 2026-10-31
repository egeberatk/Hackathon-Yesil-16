import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hackathon_projesi/models/material_item.dart';
import 'package:hackathon_projesi/screens/photo_preview_screen.dart';
import 'package:hackathon_projesi/services/analysis_service.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';
import 'package:hackathon_projesi/services/recipe_matching_service.dart';
import 'package:hackathon_projesi/widgets/project_card.dart';

// Akış testine ait sentetik tarif; gerçek katalog veya onaylı tarif içeriği değildir.
Map<String, dynamic> flowRecipe(String id, int quantity) => {
  'id': id,
  'name': 'Akış testi $id',
  'description': 'Test açıklaması',
  'required_materials': [
    {
      'material_id': 'yogurt_container',
      'name': 'Yoğurt kabı',
      'quantity': quantity,
    },
  ],
  'required_supplies': ['Test bandı'],
  'optional_supplies': [],
  'category': 'Test',
  'difficulty': 'Kolay',
  'estimated_minutes': 5,
  'steps': ['Test adımı'],
  'practical_use': 'Test amacı',
  'safety_warning': 'Test uyarısı',
  'image_prompt': '',
};

class FlowRecipeBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(
        jsonEncode({
          'approved_ids': ['test_ready', 'test_missing'],
          'projects': [
            flowRecipe('test_missing', 4),
            flowRecipe('test_ready', 3),
          ],
        }),
      );
  @override
  Future<ByteData> load(String key) => throw UnsupportedError(key);
}

void main() {
  test(
    'Yoğurt kabı eşleşmesi onay, adet toplamı ve eksik miktarı korur',
    () async {
      final projects = RecipeRepository.parse(
        await FlowRecipeBundle().loadString('test'),
      );
      final pending = MaterialItem.fromJson({
        'name': 'Yoğurt kabı',
        'material_id': 'yogurt_container',
        'quantity': 2,
        'confidence': 'uncertain',
        'requires_confirmation': true,
      });
      expect(pending.type, WasteType.yogurtContainer);
      expect(
        RecipeMatchingService.match(projects, [pending]).first.totalMissing,
        3,
      );
      final confirmed = MaterialItem(type: pending.type, quantity: 2);
      final matches = RecipeMatchingService.match(projects, [
        confirmed,
        MaterialItem(type: WasteType.yogurtContainer),
      ]);
      expect(matches.first.project.id, 'test_ready');
      expect(matches.first.canMake, isTrue);
      expect(
        matches.last.missingMaterials.single.materialId,
        'yogurt_container',
      );
      expect(matches.last.totalMissing, 1);
    },
  );

  testWidgets(
    'Fotoğraf → multipart analiz → düzenleme/onay → sıralı tarifler → detay',
    (tester) async {
      var requests = 0;
      final service = AnalysisService(
        baseUrl: 'https://backend.test',
        clientFactory: () => MockClient((request) async {
          requests++;
          expect(request.method, 'POST');
          expect(request.url.path, '/analyze');
          expect(
            request.headers['content-type'],
            contains('multipart/form-data'),
          );
          expect(
            utf8.decode(request.bodyBytes, allowMalformed: true),
            contains('name="file"'),
          );
          return http.Response(
            jsonEncode({
              'materials': [
                {
                  'name': 'Yoğurt kabı',
                  'material_id': 'yogurt_container',
                  'quantity': 2,
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
      final image = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
      );
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: FlowRecipeBundle(),
          child: MaterialApp(
            home: PhotoPreviewScreen(
              photo: XFile.fromData(image, name: 'photo.png'),
              analysisService: service,
            ),
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
      expect(requests, 1);
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
      await tester.enterText(find.byKey(const Key('material-quantity')), '3');
      await tester.ensureVisible(find.text('Kaydet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Projeleri Keşfet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Projeleri Keşfet'));
      await tester.pumpAndSettle();
      expect(find.text('Dönüşüm fikirleri'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('project-card-test_missing')),
        300,
      );
      final missingCard = tester.widget<ProjectCard>(
        find.byKey(const ValueKey('project-card-test_missing')),
      );
      expect(missingCard.match!.totalMissing, 1);
      expect(find.text('Yoğurt kabı: 1 adet eksik'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('project-card-test_ready')),
        -300,
      );
      await tester.ensureVisible(find.text('Akış testi test_ready'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Akış testi test_ready'));
      await tester.pumpAndSettle();
      expect(find.text('Proje detayı'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
