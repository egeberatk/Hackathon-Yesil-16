import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_projesi/animations/motion_sequence.dart';
import 'package:hackathon_projesi/animations/pet_planter_steps.dart';
import 'package:hackathon_projesi/core/app_theme.dart';
import 'package:hackathon_projesi/models/upcycling_project.dart';
import 'package:hackathon_projesi/screens/project_detail_screen.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';
import 'package:hackathon_projesi/widgets/pet_planter_scene.dart';
import 'package:hackathon_projesi/widgets/recipe_motion_player.dart';
import 'package:hackathon_projesi/widgets/recipe_step_card.dart';
import 'package:hackathon_projesi/widgets/recipe_step_viewer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<UpcyclingProject> catalog;
  late UpcyclingProject planter;
  setUpAll(() async {
    catalog = RecipeRepository.parse(
      await rootBundle.loadString(RecipeRepository.assetPath),
    );
    planter = catalog.singleWhere((p) => p.id == 'project_40');
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> app(
    WidgetTester tester, {
    Widget? child,
    bool reduced = false,
    double scale = 1,
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduced,
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child ?? RecipeStepViewer(project: planter),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  MotionFrame frame(WidgetTester tester) =>
      tester.widget<PetPlanterScene>(find.byType(PetPlanterScene)).frame;

  Future<void> press(WidgetTester tester, String key) async {
    final target = find.byKey(Key(key));
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await tester.pump();
  }

  test(
    'Generic clips compose all five movements, retaining completed poses',
    () {
      const sequence = MotionSequence(
        initial: {},
        leadingHold: Duration.zero,
        trailingHold: Duration.zero,
        clips: [
          MotionClip(
            kind: MotionKind.split,
            targets: {
              'a': MotionPose(offset: Offset(-20, 0)),
              'b': MotionPose(offset: Offset(20, 0)),
            },
            duration: Duration(seconds: 1),
            curve: Curves.linear,
          ),
          MotionClip(
            kind: MotionKind.rotate,
            targets: {'a': MotionPose(offset: Offset(-20, 0), angle: math.pi)},
            duration: Duration(seconds: 1),
            curve: Curves.linear,
          ),
          MotionClip(
            kind: MotionKind.insert,
            targets: {'a': MotionPose(offset: Offset(0, 10), angle: math.pi)},
            duration: Duration(seconds: 1),
            curve: Curves.linear,
          ),
          MotionClip(
            kind: MotionKind.pour,
            targets: {'fill': MotionPose(amount: 1)},
            duration: Duration(seconds: 1),
            curve: Curves.linear,
          ),
          MotionClip(
            kind: MotionKind.assemble,
            targets: {'b': MotionPose()},
            duration: Duration(seconds: 1),
            curve: Curves.linear,
          ),
        ],
      );
      expect(sequence.sample(.1)['a'].offset, const Offset(-10, 0));
      expect(sequence.sample(.1)['b'].offset, const Offset(10, 0));
      expect(sequence.sample(.3)['a'].angle, closeTo(math.pi / 2, .001));
      expect(sequence.sample(.5)['a'].offset, const Offset(-10, 5));
      expect(sequence.sample(.7)['fill'].amount, closeTo(.5, .001));
      expect(sequence.sample(.9)['b'].offset, const Offset(10, 0));
      expect(sequence.sample(1)['a'].offset, const Offset(0, 10));
      expect(sequence.sample(1)['fill'].amount, 1);
    },
  );

  test('Six real steps have metadata; the other twenty recipes have none', () {
    expect(planter.steps.length, 6);
    for (var i = 0; i < 6; i++) {
      expect(
        PetPlanterSteps.resolve(planter, i),
        same(PetPlanterSteps.steps[i]),
      );
      expect(
        PetPlanterSteps.steps[i].description.toLowerCase(),
        isNot(contains('fitil')),
      );
    }
    expect(planter.steps[2], contains('Fitili'));
    expect(PetPlanterSteps.resolve(planter, -1), isNull);
    expect(PetPlanterSteps.resolve(planter, 6), isNull);
    for (final project in catalog.where((p) => p.id != planter.id)) {
      for (var i = 0; i < project.steps.length; i++) {
        expect(PetPlanterSteps.resolve(project, i), isNull);
      }
    }
  });

  test('Inverted neck stays above water and the strip reaches into it', () {
    final end = PetPlanterSteps.steps[4].sequence.sample(1);
    expect(end['upper'].angle, math.pi);
    final capBottom = transformMotionPoint(
      const Offset(160, 60),
      PetPlanterScene.pivot,
      end['upper'],
    );
    expect(capBottom.dy, closeTo(260, .001));
    expect(capBottom.dy, lessThan(PetPlanterScene.waterSurface));
    expect(
      PetPlanterScene.stripEnd.dy,
      greaterThan(PetPlanterScene.waterSurface),
    );
    expect(end['water'].amount, 1);
    expect(end['soil'].amount, 1);
    for (final i in [3, 4, 5]) {
      expect(
        PetPlanterSteps.steps[i].sequence.sample(1)['upper'].offset,
        end['upper'].offset,
      );
    }
  });

  test('The upper part rotates entirely above the rim before insertion', () {
    final sequence = PetPlanterSteps.steps[3].sequence;
    var rotationFrames = 0;
    for (var i = 0; i <= 100; i++) {
      final sample = sequence.sample(i / 100);
      if (sample.activeKind != MotionKind.rotate) continue;
      rotationFrames++;
      // Conservative bounds include both cut corners and the attached cap.
      for (final corner in const [
        Offset(105, 60),
        Offset(215, 60),
        Offset(105, 180),
        Offset(215, 180),
      ]) {
        final point = transformMotionPoint(
          corner,
          PetPlanterScene.pivot,
          sample['upper'],
        );
        expect(
          point.dy,
          lessThan(180),
          reason: 'The rotating piece must clear the reservoir rim',
        );
        expect(point.dy, greaterThan(0));
        expect(point.dx, inInclusiveRange(0, 320));
      }
    }
    expect(rotationFrames, greaterThan(10));
  });

  testWidgets('Starts automatically and repeats beyond two complete cycles', (
    tester,
  ) async {
    await app(tester);
    expect(frame(tester)['upper'].offset, Offset.zero);
    await tester.pump(const Duration(milliseconds: 1350));
    final moving = frame(tester)['upper'].offset.dy;
    expect(moving, lessThan(0));
    expect(moving, greaterThan(-35));
    await tester.pump(PetPlanterSteps.steps.first.sequence.duration);
    expect(frame(tester)['upper'].offset.dy, closeTo(moving, .01));
    await tester.pump(PetPlanterSteps.steps.first.sequence.duration);
    expect(frame(tester)['upper'].offset.dy, closeTo(moving, .01));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pause freezes the pose, resume continues without resetting', (
    tester,
  ) async {
    await app(tester);
    await tester.pump(const Duration(milliseconds: 1300));
    await press(tester, 'motion-playback');
    final paused = frame(tester)['upper'].offset;
    expect(find.text('Animasyonu devam ettir'), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    expect(frame(tester)['upper'].offset, paused);
    await press(tester, 'motion-playback');
    expect(find.text('Animasyonu duraklat'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(frame(tester)['upper'].offset, isNot(paused));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Next/previous replaces and restarts the correct animation', (
    tester,
  ) async {
    await app(tester);
    await tester.pump(const Duration(milliseconds: 1400));
    final firstState = tester.state(find.byType(RecipeMotionPlayer));
    await press(tester, 'motion-playback');
    await press(tester, 'next-step');
    expect(firstState.mounted, isFalse);
    expect(
      tester.widget<RecipeStepCard>(find.byType(RecipeStepCard)).number,
      2,
    );
    expect(frame(tester)['edge'].amount, 0);
    expect(find.text('Animasyonu duraklat'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1400));
    expect(frame(tester)['edge'].amount, greaterThan(0));
    for (var i = 2; i < planter.steps.length; i++) {
      await press(tester, 'next-step');
      expect(
        tester.widget<RecipeStepCard>(find.byType(RecipeStepCard)).text,
        planter.steps[i],
      );
      expect(
        tester.widget<PetPlanterScene>(find.byType(PetPlanterScene)).stepIndex,
        i,
      );
    }
    for (var i = 4; i >= 0; i--) {
      await press(tester, 'previous-step');
      expect(
        tester.widget<PetPlanterScene>(find.byType(PetPlanterScene)).stepIndex,
        i,
      );
    }
    expect(frame(tester)['upper'].offset, Offset.zero);
    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion uses a static final state and no ticker', (
    tester,
  ) async {
    await app(tester, reduced: true);
    expect(frame(tester)['upper'].offset, const Offset(0, -35));
    expect(find.byKey(const Key('motion-playback')), findsNothing);
    expect(find.textContaining('Azaltılmış hareket açık'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await press(tester, 'next-step');
    expect(frame(tester)['edge'].amount, 1);
    expect(frame(tester)['hole'].amount, 1);
  });

  testWidgets('Failed optional media retains the original step text', (
    tester,
  ) async {
    await app(
      tester,
      reduced: true,
      child: RecipeStepViewer(
        project: planter,
        mediaBuilder: (context, project, index) => RecipeMotionPlayer(
          sequence: PetPlanterSteps.steps[index].sequence,
          description: 'İsteğe bağlı çizim',
          sceneBuilder: (context, frame) =>
              throw StateError('Unavailable drawing'),
        ),
      ),
    );
    expect(find.textContaining('Çizim gösterilemiyor'), findsOneWidget);
    expect(find.text(planter.steps.first), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Changing the system motion preference stops and restarts playback',
    (tester) async {
      await app(tester);
      await tester.pump(const Duration(milliseconds: 1350));
      expect(frame(tester)['upper'].offset.dy, lessThan(0));
      await app(tester, reduced: true);
      expect(frame(tester)['upper'].offset, const Offset(0, -35));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      await app(tester);
      expect(find.text('Animasyonu duraklat'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1350));
      expect(frame(tester)['upper'].offset.dy, greaterThan(-35));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Retained painted layers remain visible throughout the final hold',
    (tester) async {
      final boundary = GlobalKey();
      final step = PetPlanterSteps.steps.last;
      await app(
        tester,
        child: RecipeMotionPlayer(
          sequence: step.sequence,
          description: step.description,
          sceneBuilder: (_, value) => RepaintBoundary(
            key: boundary,
            child: ColoredBox(
              color: Colors.white,
              child: PetPlanterScene(frame: value, stepIndex: 5),
            ),
          ),
        ),
      );
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 300));
        final painted = await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          var count = 0;
          for (var p = 0; p < data!.lengthInBytes; p += 4) {
            if (data.getUint8(p) < 150 && data.getUint8(p + 1) < 150) count++;
          }
          image.dispose();
          return count;
        });
        expect(painted, greaterThan(1000));
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('All other recipes keep text-only step media', (tester) async {
    for (final project in catalog.where((p) => p.id != planter.id)) {
      await app(tester, child: RecipeStepViewer(project: project));
      expect(find.byType(RecipeMotionPlayer), findsNothing);
      expect(
        tester.widget<RecipeStepCard>(find.byType(RecipeStepCard)).media,
        isNull,
      );
      expect(find.text(project.steps.first), findsOneWidget);
    }
  });

  testWidgets('Popping the detail disposes the active controller', (
    tester,
  ) async {
    await app(
      tester,
      child: Builder(
        builder: (context) => FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProjectDetailScreen(project: planter),
            ),
          ),
          child: const Text('Aç'),
        ),
      ),
    );
    await tester.tap(find.text('Aç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final state = tester.state(find.byType(RecipeMotionPlayer));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(state.mounted, isFalse);
    expect(find.byType(RecipeMotionPlayer), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  for (final config in [
    (const Size(320, 640), 2.0),
    (const Size(640, 360), 1.5),
  ]) {
    testWidgets('Animated steps fit ${config.$1} text ${config.$2}', (
      tester,
    ) async {
      await app(tester, size: config.$1, scale: config.$2);
      for (var i = 0; i < 5; i++) {
        await press(tester, 'next-step');
        await tester.pump(const Duration(milliseconds: 1700));
        expect(tester.takeException(), isNull);
      }
      await press(tester, 'motion-playback');
      expect(find.text('Animasyonu devam ettir'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Optional animation component recording and previews', (
    tester,
  ) async {
    if (!const bool.fromEnvironment('STAGE4_PREVIEW')) return;
    var frameNumber = 0;
    final recording = GlobalKey();
    Future<void> capture(String path) async {
      final boundary =
          recording.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(path);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    for (var index = 0; index < 6; index++) {
      final step = PetPlanterSteps.steps[index];
      await tester.pumpWidget(const SizedBox());
      await app(
        tester,
        child: RecipeMotionPlayer(
          key: ValueKey(index),
          sequence: step.sequence,
          description: step.description,
          warning: step.warning,
          sceneBuilder: (context, frame) => RepaintBoundary(
            key: recording,
            child: ColoredBox(
              color: const Color(0xFFF0F6F2),
              child: Column(
                children: [
                  Text(
                    'Adım ${index + 1} / 6',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Expanded(
                    child: PetPlanterScene(frame: frame, stepIndex: index),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      // Twenty frames per second, capturing the real Flutter painter output.
      final frames = (step.sequence.duration.inMilliseconds / 50).ceil();
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        await capture(
          '.dart_tool/design-preview/stage4-frames/frame${(frameNumber++).toString().padLeft(4, '0')}.png',
        );
        if (i == frames - 2) {
          await capture('.dart_tool/design-preview/pet-step-${index + 1}.png');
        }
      }
    }
    await tester.pumpWidget(const SizedBox());
  });
}
