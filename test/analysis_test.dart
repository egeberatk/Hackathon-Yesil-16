import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hackathon_projesi/core/backend_config.dart';
import 'package:hackathon_projesi/models/material_item.dart';
import 'package:hackathon_projesi/screens/material_confirmation_screen.dart';
import 'package:hackathon_projesi/screens/photo_preview_screen.dart';
import 'package:hackathon_projesi/services/analysis_service.dart';

Map<String, dynamic> detection({
  String? id = 'pet_bottle',
  bool confirmation = true,
}) => {
  'name': 'Su şişesi',
  'material_id': id,
  'quantity': 2,
  'confidence': 'uncertain',
  'requires_confirmation': confirmation,
};

class ControlledAnalysis extends AnalysisService {
  final result = Completer<List<MaterialItem>>();
  @override
  Future<List<MaterialItem>> analyze(XFile photo) => result.future;
}

Future<void> pumpPreview(
  WidgetTester tester,
  ControlledAnalysis service,
) async {
  // Tek piksel PNG; gerçek dosya veya kamera erişimi gerekmez.
  final bytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
  );
  await tester.pumpWidget(
    MaterialApp(
      home: PhotoPreviewScreen(
        photo: XFile.fromData(bytes, name: 'image.png'),
        analysisService: service,
      ),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Analiz Et'));
  await tester.tap(find.text('Analiz Et'));
  await tester.pump();
}

void main() {
  test('Standart kimlikler korunur; bilinmeyenler zorla eşlenmez', () {
    expect(
      WasteType.values.where((type) => type.materialId != null).length,
      11,
    );
    for (final type in WasteType.values) {
      expect(WasteType.fromId(type.materialId), type);
    }
    final unknown = MaterialItem.fromJson(
      detection(id: 'wood', confirmation: false),
    );
    expect(unknown.type, WasteType.unknown);
    expect(unknown.requiresConfirmation, isTrue);
    expect(unknown.name, 'Su şişesi');
    expect(
      () => MaterialItem.fromJson({...detection(), 'quantity': '2'}),
      throwsFormatException,
    );
  });

  test('Yerel debug HTTP kabul edilir, uzak HTTP reddedilir', () {
    expect(
      BackendConfig.analyzeUri('http://192.168.1.20:8000/').toString(),
      'http://192.168.1.20:8000/analyze',
    );
    expect(BackendConfig.analyzeUri('https://example.com').scheme, 'https');
    expect(
      () => BackendConfig.analyzeUri('http://example.com'),
      throwsFormatException,
    );
    expect(() => BackendConfig.analyzeUri(''), throwsFormatException);
  });

  test('Servis fotoğrafı multipart gönderir ve JSON sonucunu okur', () async {
    final service = AnalysisService(
      baseUrl: 'http://192.168.1.20:8000',
      clientFactory: () => MockClient((request) async {
        expect(request.url.path, '/analyze');
        expect(
          request.headers['content-type'],
          contains('multipart/form-data'),
        );
        expect(request.body, contains('name="file"'));
        return http.Response(
          jsonEncode({
            'materials': [detection()],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final items = await service.analyze(
      XFile.fromData(Uint8List.fromList([1, 2, 3])),
    );
    expect(items.single.type, WasteType.plastic);
    expect(items.single.quantity, 2);
    expect(items.single.name, 'Su şişesi');
  });

  test('Servis API hatasını okunabilir biçimde aktarır', () async {
    final service = AnalysisService(
      baseUrl: 'https://example.com',
      clientFactory: () => MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'Analiz limiti doldu.'},
          }),
          429,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    await expectLater(
      service.analyze(XFile.fromData(Uint8List(1))),
      throwsA(
        isA<AnalysisException>().having(
          (error) => error.message,
          'message',
          'Analiz limiti doldu.',
        ),
      ),
    );
  });

  test('Servis bozuk yanıtı ve bağlantı hatasını yakalar', () async {
    for (final fail in [false, true]) {
      final service = AnalysisService(
        baseUrl: 'https://example.com',
        clientFactory: () => MockClient((_) async {
          if (fail) throw http.ClientException('offline');
          return http.Response('{"materials":[{"quantity":0}]}', 200);
        }),
      );
      await expectLater(
        service.analyze(XFile.fromData(Uint8List(1))),
        throwsA(isA<AnalysisException>()),
      );
    }
  });

  testWidgets('Analiz yükleniyor durumundan onay ekranına geçer', (
    tester,
  ) async {
    final service = ControlledAnalysis();
    await pumpPreview(tester, service);
    expect(find.text('Fotoğraf analiz ediliyor…'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Analiz Et'))
          .onPressed,
      isNull,
    );
    service.result.complete([MaterialItem.fromJson(detection())]);
    await tester.pumpAndSettle();
    expect(find.text('Malzemelerini Doğrula'), findsOneWidget);
    expect(find.text('Su şişesi'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Projeleri Keşfet'),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Analiz hatasında manuel boş liste kullanılabilir', (
    tester,
  ) async {
    final service = ControlledAnalysis();
    await pumpPreview(tester, service);
    service.result.completeError(
      const AnalysisException('Sunucuya ulaşılamadı.'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sunucuya ulaşılamadı.'), findsOneWidget);
    await tester.ensureVisible(find.text('Manuel malzeme seç'));
    await tester.tap(find.text('Manuel malzeme seç'));
    await tester.pumpAndSettle();
    expect(
      find.text('Henüz malzeme yok. Bir malzeme ekleyerek başla.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Malzemeyi sil'), findsNothing);
  });

  testWidgets('Bilinmeyen nesne tür ve ad düzenlenerek onaylanır', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MaterialConfirmationScreen(
          initialItems: [MaterialItem.fromJson(detection(id: null))],
        ),
      ),
    );
    await tester.ensureVisible(find.byTooltip('Malzemeyi düzenle'));
    await tester.tap(find.byTooltip('Malzemeyi düzenle'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(
      find.text('Uygun bir tür seç veya nesneyi listeden sil.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byType(DropdownButtonFormField<WasteType>));
    await tester.tap(find.byType(DropdownButtonFormField<WasteType>));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Cam kavanoz'),
      -150,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cam kavanoz').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('material-name')),
      'Küçük kavanoz',
    );
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('Küçük kavanoz'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Projeleri Keşfet'),
          )
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
}
