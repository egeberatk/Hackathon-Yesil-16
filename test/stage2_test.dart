import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hackathon_projesi/core/app_theme.dart';
import 'package:hackathon_projesi/models/material_item.dart';
import 'package:hackathon_projesi/screens/home_screen.dart';
import 'package:hackathon_projesi/screens/photo_preview_screen.dart';
import 'package:hackathon_projesi/screens/material_confirmation_screen.dart';
import 'package:hackathon_projesi/screens/projects_screen.dart';
import 'package:hackathon_projesi/services/analysis_service.dart';
import 'package:hackathon_projesi/services/photo_service.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';
import 'package:hackathon_projesi/widgets/analysis_photo.dart';
import 'package:hackathon_projesi/widgets/material_card.dart';

class StageBundle extends CachingAssetBundle {
  StageBundle(this.source);
  final String source;
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(source);
  @override
  Future<ByteData> load(String key) => throw UnsupportedError(key);
}

class TestPhotos extends PhotoService {
  XFile? next;
  Object? error;
  final sources = <ImageSource>[];
  @override
  Future<XFile?> recover() async => null;
  @override
  Future<XFile?> pick(ImageSource source) async {
    sources.add(source);
    if (error != null) throw error!;
    return next;
  }
}

class TestAnalysis extends AnalysisService {
  TestAnalysis(this.respond);
  final Future<List<MaterialItem>> Function() respond;
  final photos = <XFile>[];
  @override
  Future<List<MaterialItem>> analyze(XFile photo) {
    photos.add(photo);
    return respond();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String catalog;
  late Uint8List sample;
  setUpAll(() async {
    catalog = await rootBundle.loadString(RecipeRepository.assetPath);
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    // Native drawing used only for test previews; no photo or catalog data is replaced.
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    c.drawRect(
      const Rect.fromLTWH(0, 0, 640, 480),
      Paint()..color = const Color(0xFFF2EEE4),
    );
    c.drawRect(
      const Rect.fromLTWH(0, 330, 640, 150),
      Paint()..color = const Color(0xFFDCD0BB),
    );
    c.drawOval(
      const Rect.fromLTWH(90, 360, 440, 35),
      Paint()..color = const Color(0x22000000),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(130, 140, 110, 235),
        const Radius.circular(22),
      ),
      Paint()..color = const Color(0xFFBAD8C6),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(150, 96, 70, 55),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF1B4332),
    );
    c.drawRect(
      const Rect.fromLTWH(130, 230, 110, 60),
      Paint()..color = Colors.white,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(330, 190, 150, 185),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xFFD6E4D4),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(325, 175, 160, 25),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFFB69364),
    );
    c.drawRect(
      const Rect.fromLTWH(360, 260, 90, 55),
      Paint()..color = const Color(0xFFFFFAED),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(640, 480);
    sample = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();
    image.dispose();
    picture.dispose();
  });

  Future<void> app(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(390, 844),
    double scale = 1,
    GlobalKey? boundary,
    bool settle = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: StageBundle(catalog),
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: screen,
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  XFile photo([String name = 'test-photo.png']) =>
      XFile.fromData(sample, name: name);
  Future<void> tap(
    WidgetTester tester,
    Finder finder, {
    bool settle = true,
  }) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Finder cardAction(int index, String label) => find.descendant(
    of: find.byType(MaterialCard).at(index),
    matching: find.text(label),
  );
  Finder cardTooltip(int index, String tooltip) => find.descendant(
    of: find.byType(MaterialCard).at(index),
    matching: find.byTooltip(tooltip),
  );
  bool enabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(find.byKey(const Key('find-recipes')))
          .onPressed !=
      null;

  for (final source in ImageSource.values) {
    testWidgets('Ana sayfa ${source.name} iptali önizleme açmadan geri döner', (
      tester,
    ) async {
      final photos = TestPhotos();
      await app(tester, HomeScreen(photoService: photos));
      if (source == ImageSource.camera) {
        await tap(tester, find.text('Atığını Tara'));
        await tap(tester, find.text('Fotoğraf çek'));
      } else {
        await tap(tester, find.text('Galeriden seç'));
      }
      expect(photos.sources, [source]);
      expect(find.byType(PhotoPreviewScreen), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Atığını Tara'),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Önizlemede ${source.name} iptali seçili fotoğrafı korur', (
      tester,
    ) async {
      final photos = TestPhotos();
      await app(
        tester,
        PhotoPreviewScreen(photo: photo(), photoService: photos),
      );
      await tap(
        tester,
        find.text(
          source == ImageSource.camera ? 'Yeniden çek' : 'Fotoğrafı değiştir',
        ),
      );
      expect(photos.sources, [source]);
      expect(
        tester.widget<AnalysisPhoto>(find.byType(AnalysisPhoto)).bytes,
        sample,
      );
      expect(find.text('Fotoğraf seçilemedi'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Fotoğrafı değiştirdikten sonra analiz yeni XFile kullanır', (
    tester,
  ) async {
    final photos = TestPhotos()..next = photo('replacement.png');
    final service = TestAnalysis(() async => []);
    await app(
      tester,
      PhotoPreviewScreen(
        photo: photo(),
        photoService: photos,
        analysisService: service,
      ),
    );
    await tap(tester, find.text('Fotoğrafı değiştir'));
    await tap(tester, find.text('Analiz Et'));
    expect(service.photos.single, same(photos.next));
    expect(
      find.text('Henüz malzeme yok. Bir malzeme ekleyerek başla.'),
      findsOneWidget,
    );
  });

  testWidgets('Kamera izni hatası seçim seçeneklerini kullanılabilir bırakır', (
    tester,
  ) async {
    final photos = TestPhotos()
      ..error = PlatformException(code: 'camera_access_denied');
    await app(tester, PhotoPreviewScreen(photo: photo(), photoService: photos));
    await tap(tester, find.text('Yeniden çek'));
    expect(find.text('Fotoğraf seçilemedi'), findsOneWidget);
    expect(find.textContaining('Cihaz ayarlarından izni'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Yeniden çek'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'Aynı karede çift tıklama tek analiz başlatır; hata sonrası tekrar denenir',
    (tester) async {
      final pending = Completer<List<MaterialItem>>();
      var attempts = 0;
      final service = TestAnalysis(
        () => ++attempts == 1 ? pending.future : Future.value([]),
      );
      await app(
        tester,
        PhotoPreviewScreen(photo: photo(), analysisService: service),
      );
      final analyze = find.text('Analiz Et');
      await tester.ensureVisible(analyze);
      await tester.tap(analyze);
      await tester.tap(analyze);
      await tester.pump();
      expect(service.photos, hasLength(1));
      expect(
        tester.widget<AnalysisPhoto>(find.byType(AnalysisPhoto)).active,
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Yeni fikirler yolda.').hitTestable(), findsOneWidget);
      expect(find.text('Fotoğraf inceleniyor'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining(RegExp(r'\d+\s*%')), findsNothing);
      expect(
        tester.widget<PopScope>(find.byType(PopScope).first).canPop,
        isFalse,
      );
      pending.completeError(
        const AnalysisException('Analiz zaman aşımına uğradı.'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Analiz zaman aşımına uğradı.'), findsOneWidget);
      await tap(tester, find.text('Yeniden dene'));
      expect(service.photos, hasLength(2));
      expect(find.byType(MaterialConfirmationScreen), findsOneWidget);
    },
  );

  for (final scenario in ['network', 'timeout', 'invalid-json']) {
    testWidgets(
      '$scenario backend hatası anlaşılır hata ve yeniden deneme sunar',
      (tester) async {
        final service = AnalysisService(
          baseUrl: 'https://test.example',
          clientFactory: () => MockClient((_) async {
            if (scenario == 'network') throw http.ClientException('offline');
            if (scenario == 'timeout') throw TimeoutException('test');
            return http.Response('{"materials":[{"quantity":0}]}', 200);
          }),
        );
        await app(
          tester,
          PhotoPreviewScreen(photo: photo(), analysisService: service),
        );
        await tap(tester, find.text('Analiz Et'));
        expect(find.text('Analiz tamamlanamadı'), findsOneWidget);
        expect(find.text('Yeniden dene'), findsOneWidget);
        expect(find.byType(MaterialConfirmationScreen), findsNothing);
        expect(
          tester.widget<AnalysisPhoto>(find.byType(AnalysisPhoto)).active,
          isFalse,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Yalnızca açıkça onaylanan satırlar doğru miktarlarla aktarılır',
    (tester) async {
      await app(
        tester,
        MaterialConfirmationScreen(
          initialItems: [
            MaterialItem(type: WasteType.yogurtContainer),
            MaterialItem(type: WasteType.yogurtContainer, quantity: 2),
            MaterialItem(type: WasteType.unknown, quantity: 9),
            MaterialItem(type: WasteType.glass, quantity: 3),
          ],
        ),
      );
      expect(enabled(tester), isFalse);
      await tap(tester, cardAction(0, 'Onayla'));
      expect(enabled(tester), isTrue);
      await tap(tester, cardTooltip(0, 'Miktarı artır'));
      expect(enabled(tester), isFalse);
      await tap(tester, cardAction(0, 'Onayla'));
      await tap(tester, cardAction(1, 'Onayla'));
      await tap(tester, find.text('Tarifleri Bul'));
      final items = tester
          .widget<ProjectsScreen>(find.byType(ProjectsScreen))
          .items;
      expect(items, hasLength(2));
      expect(
        items.every(
          (item) =>
              item.type == WasteType.yogurtContainer &&
              !item.requiresConfirmation,
        ),
        isTrue,
      );
      expect(items.fold<int>(0, (sum, item) => sum + item.quantity), 4);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Manuel ekleme, adet doğrulama, azaltma, onay geri alma ve silme',
    (tester) async {
      await app(tester, const MaterialConfirmationScreen(initialItems: []));
      expect(enabled(tester), isFalse);
      await tap(tester, find.text('Malzeme ekle'));
      await tester.enterText(
        find.byKey(const Key('material-name')),
        'Küçük kavanoz',
      );
      await tester.enterText(find.byKey(const Key('material-quantity')), '0');
      await tap(tester, find.text('Kaydet'));
      expect(find.text('1 ile 999 arasında tam sayı gir.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('material-quantity')), '3');
      await tap(tester, find.text('Kaydet'));
      expect(enabled(tester), isTrue);
      await tap(tester, find.byTooltip('Miktarı azalt'));
      expect(find.text('2 adet'), findsOneWidget);
      expect(enabled(tester), isFalse);
      await tap(tester, find.text('Onayla'));
      await tap(tester, find.text('Onayı geri al'));
      expect(enabled(tester), isFalse);
      await tap(tester, find.byTooltip('Malzemeyi sil'));
      expect(find.byType(MaterialCard), findsNothing);
      expect(
        find.text('Henüz malzeme yok. Bir malzeme ekleyerek başla.'),
        findsOneWidget,
      );
    },
  );

  for (final settings in [
    (const Size(320, 640), 2.0),
    (const Size(640, 360), 1.5),
  ]) {
    testWidgets(
      'Onay, klavye ve önizleme ${settings.$1} metin ${settings.$2} taşmaz',
      (tester) async {
        await app(
          tester,
          MaterialConfirmationScreen(
            initialItems: [
              MaterialItem(
                type: WasteType.unknown,
                name: 'Türü henüz tanınmayan uzun nesne adı',
              ),
            ],
          ),
          size: settings.$1,
          scale: settings.$2,
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byKey(const Key('find-recipes'))).height,
          greaterThanOrEqualTo(56),
        );
        await tap(tester, find.byTooltip('Malzemeyi düzenle'));
        tester.view.viewInsets = const FakeViewPadding(bottom: 180);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('material-name')));
        await tester.enterText(
          find.byKey(const Key('material-name')),
          'Düzenlenen nesne',
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await tap(tester, find.text('Vazgeç'));
        await app(
          tester,
          PhotoPreviewScreen(photo: photo()),
          size: settings.$1,
          scale: settings.$2,
        );
        await tester.ensureVisible(find.text('Analiz Et'));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('İsteğe bağlı ikinci aşama ekran önizlemeleri', (tester) async {
    if (!const bool.fromEnvironment('STAGE2_PREVIEW')) return;
    Future<void> capture(GlobalKey key, String name) async {
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('.dart_tool/design-preview/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    var key = GlobalKey();
    final pending = Completer<List<MaterialItem>>();
    await app(
      tester,
      PhotoPreviewScreen(
        photo: photo(),
        analysisService: TestAnalysis(() => pending.future),
      ),
      boundary: key,
    );
    await capture(key, 'photo-preview');
    await tap(tester, find.text('Analiz Et'), settle: false);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 850));
    await capture(key, 'analysis');
    pending.completeError(
      const AnalysisException(
        'Analiz zaman aşımına uğradı. Yeniden deneyebilir veya manuel giriş kullanabilirsin.',
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Yeniden dene'));
    await tester.pumpAndSettle();
    await capture(key, 'analysis-error');
    key = GlobalKey();
    await app(
      tester,
      MaterialConfirmationScreen(
        initialItems: [
          MaterialItem(
            type: WasteType.plastic,
            quantity: 2,
            name: 'Plastik su şişesi',
          ),
          MaterialItem(type: WasteType.glass, name: 'Cam kavanoz'),
          MaterialItem(type: WasteType.unknown, name: 'Tanımlanamayan nesne'),
        ],
      ),
      boundary: key,
    );
    await tap(tester, cardAction(0, 'Onayla'));
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, 1200),
    );
    await tester.pumpAndSettle();
    await capture(key, 'materials');
  });
}
