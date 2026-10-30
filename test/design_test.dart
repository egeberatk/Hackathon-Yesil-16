import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_projesi/core/app_theme.dart';
import 'package:hackathon_projesi/main.dart';
import 'package:hackathon_projesi/models/material_item.dart';
import 'package:hackathon_projesi/screens/projects_screen.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';
import 'package:hackathon_projesi/widgets/project_card.dart';

class DesignBundle extends CachingAssetBundle {
  DesignBundle(this.source);
  final String source;
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(source);
  @override
  Future<ByteData> load(String key) => throw UnsupportedError(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String catalog;
  setUpAll(() async {
    catalog = await rootBundle.loadString(RecipeRepository.assetPath);
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  Future<void> home(
    WidgetTester tester,
    Size size,
    double scale, {
    GlobalKey? boundary,
    EdgeInsets safeArea = EdgeInsets.zero,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    // Skip Android lost-image recovery in widget tests, keeping production intact.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: DesignBundle(catalog),
          child: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
              padding: safeArea,
              viewPadding: safeArea,
            ),
            child: RepaintBoundary(key: boundary, child: const ReBornApp()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  for (final size in [const Size(360, 800), const Size(390, 844)]) {
    testWidgets(
      'Kompakt ana sayfa $size ilk tarif görselini kaydırmadan gösterir',
      (tester) async {
        await home(
          tester,
          size,
          1,
          safeArea: const EdgeInsets.symmetric(vertical: 24),
        );
        final hero = tester.getSize(find.byKey(const ValueKey('scan-hero')));
        if (size.width == 390) {
          // Measured with the same font/viewport before the compact layout.
          const originalHeight = 456.69565217391306;
          expect(hero.height / originalHeight, inInclusiveRange(.70, .75));
        }
        final button = find.widgetWithText(FilledButton, 'Atığını Tara');
        expect(tester.getSize(button).height, greaterThanOrEqualTo(56));
        final navigationTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
        expect(
          tester.getBottomLeft(find.text('İlham Al')).dy,
          lessThan(navigationTop),
        );
        expect(
          tester.getTopLeft(find.byType(ProjectCard).first).dy + 32,
          lessThan(navigationTop),
        );
        expect(find.text('Atığını Tara').hitTestable(), findsOneWidget);
        expect(find.text('Galeriden seç').hitTestable(), findsOneWidget);
        final heading = tester.widget<Text>(
          find.text('Birlikte yeni bir hayat verelim.'),
        );
        expect(heading.style!.fontSize, inInclusiveRange(28, 30));
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final config in [
    (const Size(320, 640), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(320, 640), 2.0),
    (const Size(640, 360), 1.5),
  ]) {
    testWidgets(
      'Ana sayfa ve navigasyon ${config.$1} metin ${config.$2} taşmaz',
      (tester) async {
        await home(tester, config.$1, config.$2);
        expect(find.text('Ne Dönüştürmek İstersin?'), findsOneWidget);
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.text('Ne Dönüştürmek İstersin?')),
          ).scale(10),
          closeTo(config.$2 * 10, .01),
        );
        expect(find.text('İlham Al'), findsOneWidget);
        expect(find.byType(NavigationDestination), findsNWidgets(3));
        expect(find.textContaining('kurtarılan'), findsNothing);
        await tester.ensureVisible(find.byKey(const Key('inspiration-scroll')));
        await tester.drag(
          find.byKey(const Key('inspiration-scroll')),
          const Offset(-260, 0),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.widgetWithText(NavigationDestination, 'Projeler'),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.byType(ProjectCard).evaluate().length, lessThan(21));
        expect(tester.takeException(), isNull);
        await tester.tap(find.widgetWithText(NavigationDestination, 'Tara'));
        await tester.pumpAndSettle();
        expect(find.text('Fotoğraf çek'), findsOneWidget);
        expect(find.text('Galeriden seç'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('Yeni temayla eksik malzemeler ve rozetler dar ekranda taşmaz', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: DesignBundle(catalog),
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: ProjectsScreen(
            items: [MaterialItem(type: WasteType.yogurtContainer)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(ProjectCard).evaluate().length, lessThan(21));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('missing-section')),
      400,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ana sayfa, galeri ve proje detayına erişim korunur', (
    tester,
  ) async {
    await home(tester, const Size(390, 844), 1);
    await tester.ensureVisible(find.byType(ProjectCard).first);
    await tester.tap(find.byType(ProjectCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Adım adım dönüşüm'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Atığını Tara'));
    await tester.tap(find.text('Atığını Tara'));
    await tester.pumpAndSettle();
    expect(find.text('Fotoğraf çek'), findsOneWidget);
    expect(find.text('Galeriden seç'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('İsteğe bağlı yerel tasarım önizlemesi', (tester) async {
    final key = GlobalKey();
    await home(tester, const Size(390, 844), 1, boundary: key);
    Future<void> capture(String name) async {
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

    if (const bool.fromEnvironment('DESIGN_PREVIEW')) {
      debugPrint(
        'Scan hero height: ${tester.getSize(find.byKey(const ValueKey('scan-hero'))).height}',
      );
      await capture('home');
      await tester.ensureVisible(find.byKey(const Key('inspiration-scroll')));
      await tester.pumpAndSettle();
      await capture('inspiration');
      await tester.tap(find.widgetWithText(NavigationDestination, 'Projeler'));
      await tester.pumpAndSettle();
      await capture('projects');
    }
    expect(tester.takeException(), isNull);
  });
}
