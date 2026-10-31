import 'helpers/mock_photo_platform.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_projesi/animations/eco_mascot_motion.dart';
import 'package:hackathon_projesi/core/app_theme.dart';
import 'package:hackathon_projesi/core/eco_guide_messages.dart';
import 'package:hackathon_projesi/models/material_item.dart';
import 'package:hackathon_projesi/screens/home_screen.dart';
import 'package:hackathon_projesi/screens/material_confirmation_screen.dart';
import 'package:hackathon_projesi/screens/pet_guide_complete_screen.dart';
import 'package:hackathon_projesi/services/photo_service.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hackathon_projesi/widgets/eco_guide.dart';
import 'package:hackathon_projesi/widgets/eco_mascot_avatar.dart';

class _Photos extends PhotoService {
  @override
  Future<XFile?> recover() async => null;
  @override
  Future<XFile?> pick(ImageSource source) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(mockPhotoPlatform);
  late ui.Image art;
  late HomeTestAssets homeAssets;
  setUpAll(() async {
    art = await EcoMascotArt.load();
    homeAssets = HomeTestAssets(
      await rootBundle.loadString(RecipeRepository.assetPath),
    );
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    bool reduced = false,
    bool visible = true,
    Size size = const Size(390, 844),
    double scale = 1,
    GlobalKey? boundary,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: DefaultAssetBundle(
          bundle: homeAssets,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: reduced,
                textScaler: TextScaler.linear(scale),
              ),
              child: TickerMode(enabled: visible, child: child!),
            ),
            home: child,
          ),
        ),
      ),
    );
    // The decoded asset Future originates outside the fake test clock.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  EcoMascotPainter painter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(find.byKey(const Key('eco-mascot-paint')))
              .painter!
          as EcoMascotPainter;

  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final output = File('.dart_tool/mascot/previews/$name.png');
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  test('Six distinct gentle motions keep the official hand roles', () {
    expect(
      EcoMascotPose.sample(EcoMascotMood.greeting, .25).redArm.abs(),
      greaterThan(.1),
    );
    expect(EcoMascotPose.sample(EcoMascotMood.greeting, .25).blueArm, 0);
    expect(EcoMascotPose.sample(EcoMascotMood.thinking, .5).head, lessThan(0));
    expect(
      EcoMascotPose.sample(EcoMascotMood.explaining, .5).blueArm,
      lessThan(-.1),
    );
    expect(
      EcoMascotPose.sample(EcoMascotMood.celebrating, .5).lift,
      lessThan(-20),
    );
    expect(
      EcoMascotPose.sample(EcoMascotMood.warning, .25).sway.abs(),
      greaterThan(2),
    );
    expect(EcoMascotPose.sample(EcoMascotMood.idle, .67).eyeOpen, lessThan(.1));
    for (final mood in EcoMascotMood.values) {
      final neutral = EcoMascotPose.sample(mood, 1);
      expect(neutral.eyeOpen, 1);
      expect(neutral.lift.abs(), lessThan(.001));
      expect(neutral.redArm.abs(), lessThan(.001));
    }
  });

  test('Context selects concise messages and qualified collection advice', () {
    expect(
      EcoGuideMessages.mood(EcoGuideScene.analyzing),
      EcoMascotMood.thinking,
    );
    expect(
      EcoGuideMessages.mood(EcoGuideScene.completed),
      EcoMascotMood.celebrating,
    );
    expect(EcoGuideMessages.text(EcoGuideScene.noMaterials), contains('Yerel'));
    expect(EcoGuideMessages.text(EcoGuideScene.completed), contains('yerel'));
    for (final scene in EcoGuideScene.values) {
      expect(EcoGuideMessages.text(scene).length, lessThan(150));
    }
  });

  testWidgets('Automatic pulse, rest, resume and disposal', (tester) async {
    await mount(
      tester,
      const Scaffold(body: EcoGuide(scene: EcoGuideScene.home)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    final value = painter(tester).progress.value;
    expect(value, greaterThan(0));
    await tester.tap(find.byType(EcoMascotAvatar));
    await tester.pump(const Duration(seconds: 2));
    expect(painter(tester).progress.value, value);
    expect(find.byTooltip('Maskotu devam ettir'), findsOneWidget);
    await tester.tap(find.byType(EcoMascotAvatar));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(painter(tester).progress.value, greaterThan(value));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(milliseconds: 300));
    expect(painter(tester).mood, EcoMascotMood.idle);
    expect(painter(tester).progress.value, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 20));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Reduced motion and hidden routes stay still; context resets mood',
    (tester) async {
      await mount(
        tester,
        const Scaffold(body: EcoGuide(scene: EcoGuideScene.home)),
        reduced: true,
      );
      await tester.pump(const Duration(seconds: 10));
      expect(painter(tester).progress.value, 1);
      expect(tester.binding.transientCallbackCount, 0);
      await mount(
        tester,
        const Scaffold(body: EcoGuide(scene: EcoGuideScene.analyzing)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(painter(tester).mood, EcoMascotMood.thinking);
      await mount(
        tester,
        const Scaffold(body: EcoGuide(scene: EcoGuideScene.analyzing)),
        visible: false,
      );
      final value = painter(tester).progress.value;
      await tester.pump(const Duration(seconds: 10));
      expect(painter(tester).progress.value, value);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    testWidgets('Context balloons and return fit $size at 2x text', (
      tester,
    ) async {
      for (final scene in EcoGuideScene.values) {
        await mount(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EcoGuide(scene: scene),
              ),
            ),
          ),
          reduced: true,
          size: size,
          scale: 2,
        );
        expect(tester.takeException(), isNull);
      }
      await mount(
        tester,
        const PetGuideCompleteScreen(),
        reduced: true,
        size: size,
        scale: 2,
      );
      final button = find.byKey(const Key('return-to-home'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Optional real Flutter mascot and screen previews', (
    tester,
  ) async {
    if (!const bool.fromEnvironment('MASCOT_PREVIEW')) return;
    final key = GlobalKey();
    for (final mood in EcoMascotMood.values) {
      await mount(
        tester,
        Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 330,
              child: CustomPaint(
                painter: EcoMascotPainter(
                  image: art,
                  mood: mood,
                  progress: const AlwaysStoppedAnimation(.25),
                ),
              ),
            ),
          ),
        ),
        reduced: true,
        boundary: key,
      );
      await capture(tester, key, mood.name);
    }
    for (final item in <String, Widget>{
      'home': HomeScreen(photoService: _Photos()),
      'materials': MaterialConfirmationScreen(
        initialItems: [
          MaterialItem(type: WasteType.plastic, quantity: 2),
          MaterialItem(type: WasteType.yogurtContainer),
        ],
      ),
      'completed': const PetGuideCompleteScreen(),
    }.entries) {
      await mount(tester, item.value, reduced: true, boundary: key);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      await capture(tester, key, item.key);
      await tester.pumpWidget(const SizedBox());
    }
    await mount(
      tester,
      const Scaffold(
        body: Center(
          child: EcoMascotAvatar(mood: EcoMascotMood.greeting, size: 330),
        ),
      ),
      size: const Size(390, 460),
      boundary: key,
    );
    for (var frame = 0; frame < 36; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
      await capture(tester, key, 'frames/${frame.toString().padLeft(3, '0')}');
    }
    await tester.pumpWidget(const SizedBox());
  });
}
