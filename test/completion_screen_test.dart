import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_projesi/animations/eco_mascot_motion.dart';
import 'package:hackathon_projesi/core/app_brand.dart';
import 'package:hackathon_projesi/core/app_theme.dart';
import 'package:hackathon_projesi/main.dart';
import 'package:hackathon_projesi/models/upcycling_project.dart';
import 'package:hackathon_projesi/screens/home_screen.dart';
import 'package:hackathon_projesi/screens/project_complete_screen.dart';
import 'package:hackathon_projesi/screens/project_detail_screen.dart';
import 'package:hackathon_projesi/services/recipe_photo_repository.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';
import 'package:hackathon_projesi/widgets/eco_mascot_avatar.dart';
import 'package:hackathon_projesi/widgets/recipe_motion_player.dart';

import 'helpers/mock_photo_platform.dart';

class _Assets extends CachingAssetBundle {
  _Assets(this.catalog, this.photos);
  final String catalog, photos;
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(
        key == RecipePhotoRepository.assetPath ? photos : catalog,
      );
  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<UpcyclingProject> recipes;
  late _Assets assets;
  setUp(mockPhotoPlatform);
  setUpAll(() async {
    final catalog = await rootBundle.loadString(RecipeRepository.assetPath);
    recipes = RecipeRepository.parse(catalog);
    assets = _Assets(
      catalog,
      await rootBundle.loadString(RecipePhotoRepository.assetPath),
    );
    await EcoMascotArt.load();
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    // Optional local preview font; phones use their system emoji fallback.
    final emojiFont = File('C:/Windows/Fonts/seguiemj.ttf');
    if (const bool.fromEnvironment('COMPLETION_PREVIEW') &&
        await emojiFont.exists()) {
      final bytes = await emojiFont.readAsBytes();
      await (FontLoader(
        'Segoe UI Emoji',
      )..addFont(SynchronousFuture(ByteData.sublistView(bytes)))).load();
    }
  });

  Future<void> mount(
    WidgetTester tester,
    Widget home, {
    bool reduced = true,
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
        bundle: assets,
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: reduced,
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(top: 24, bottom: 24),
              ),
              child: child!,
            ),
            home: home,
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    if (reduced) await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, Key key) async {
    final button = find.byKey(key);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  testWidgets('Display name is updated without renaming the technical app', (
    tester,
  ) async {
    await mount(tester, const ReBornApp());
    expect(
      tester.widgetList<MaterialApp>(find.byType(MaterialApp)).last.title,
      AppBrand.name,
    );
    expect(find.text(AppBrand.name), findsOneWidget);
    expect(
      find.textContaining(RegExp('reborn', caseSensitive: false)),
      findsNothing,
    );
    final android = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(android, contains('android:label="${AppBrand.name}"'));
    expect(
      File('android/app/build.gradle.kts').readAsStringSync(),
      contains('applicationId = "com.example.hackathon_projesi"'),
    );
    await tester.pumpWidget(const SizedBox());
  });

  for (final id in ['project_40', 'project_01']) {
    for (final back in [false, true]) {
      testWidgets(
        '$id finish then ${back ? 'system back' : 'button'} clears the entire stack',
        (tester) async {
          await mount(tester, const HomeScreen());
          final oldHome = tester.state(find.byType(HomeScreen));
          final navigator = Navigator.of(
            tester.element(find.byType(HomeScreen)),
          );
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  Scaffold(appBar: AppBar(title: const Text('Eski öneriler'))),
            ),
          );
          await tester.pumpAndSettle();
          final recipe = recipes.singleWhere((p) => p.id == id);
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => ProjectDetailScreen(project: recipe),
            ),
          );
          await tester.pumpAndSettle();
          await press(tester, const Key('start-building'));
          for (var i = 0; i < recipe.steps.length; i++) {
            await press(tester, const Key('next-step'));
          }
          expect(find.byType(ProjectCompleteScreen), findsOneWidget);
          expect(oldHome.mounted, isFalse);
          expect(find.byType(RecipeMotionPlayer), findsNothing);
          expect(find.text('Eski öneriler'), findsNothing);
          if (back) {
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
          } else {
            expect(find.text('Ana Menüye Dön'), findsOneWidget);
            await press(tester, const Key('return-to-home'));
          }
          expect(find.byType(HomeScreen), findsOneWidget);
          expect(find.byKey(const ValueKey('home-body')), findsOneWidget);
          expect(
            tester
                .widget<NavigationBar>(find.byType(NavigationBar))
                .selectedIndex,
            0,
          );
          final current = Navigator.of(tester.element(find.byType(HomeScreen)));
          expect(current.canPop(), isFalse);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.byType(ProjectCompleteScreen), findsNothing);
          expect(find.byType(ProjectDetailScreen), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets(
    'Large mascot celebrates once then rests; leaving disposes ticker',
    (tester) async {
      await mount(tester, const ProjectCompleteScreen(), reduced: false);
      final avatar = tester.getSize(find.byKey(const Key('completion-mascot')));
      expect(avatar.height / 844, inInclusiveRange(.38, .5));
      await tester.pump(const Duration(milliseconds: 450));
      EcoMascotPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.byKey(const Key('eco-mascot-paint')),
                  )
                  .painter!
              as EcoMascotPainter;
      expect(painter().mood, EcoMascotMood.celebrating);
      expect(painter().pose.lift, lessThan(0));
      expect(painter().pose.redArm, greaterThan(0));
      expect(painter().pose.blueArm, lessThan(0));
      expect(painter().pose.eyeOpen, lessThan(1));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(painter().mood, EcoMascotMood.idle);
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pump(const Duration(seconds: 10));
      expect(painter().mood, EcoMascotMood.idle);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 20));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final config in [
    (const Size(320, 640), 1.0),
    (const Size(320, 640), 2.0),
    (const Size(640, 360), 2.0),
    (const Size(390, 844), 3.0),
  ]) {
    testWidgets(
      'Completion fits ${config.$1} at ${config.$2} text with fixed action',
      (tester) async {
        await mount(
          tester,
          const ProjectCompleteScreen(),
          size: config.$1,
          scale: config.$2,
        );
        final button = find.byKey(const Key('return-to-home'));
        final before = tester.getRect(button);
        expect(button.hitTestable(), findsOneWidget);
        expect(before.height, greaterThanOrEqualTo(56));
        expect(before.bottom, lessThanOrEqualTo(config.$1.height - 24));
        await tester.ensureVisible(find.byKey(const Key('completion-message')));
        await tester.pumpAndSettle();
        expect(tester.getRect(button), before);
        expect(find.byType(EcoMascotAvatar), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('Optional real Flutter completion previews', (tester) async {
    if (!const bool.fromEnvironment('COMPLETION_PREVIEW')) return;
    for (final size in [const Size(390, 844), const Size(320, 640)]) {
      final key = GlobalKey();
      await mount(
        tester,
        const ProjectCompleteScreen(),
        boundary: key,
        size: size,
      );
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
          '.dart_tool/completion/previews/completed-${size.width.toInt()}.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    }
  });
}
