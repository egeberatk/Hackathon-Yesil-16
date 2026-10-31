import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hackathon_projesi/animations/workshop_steps.dart';
import 'package:hackathon_projesi/core/app_theme.dart';
import 'package:hackathon_projesi/models/upcycling_project.dart';
import 'package:hackathon_projesi/screens/home_screen.dart';
import 'package:hackathon_projesi/screens/project_detail_screen.dart';
import 'package:hackathon_projesi/screens/workshop_recipe_guide.dart';
import 'package:hackathon_projesi/services/photo_service.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';
import 'package:hackathon_projesi/widgets/project_card.dart';
import 'package:hackathon_projesi/widgets/recipe_motion_player.dart';
import 'package:hackathon_projesi/widgets/recipe_step_card.dart';
import 'package:hackathon_projesi/widgets/recipe_step_viewer.dart';
import 'package:hackathon_projesi/widgets/workshop_step_scene.dart';

class _Catalog extends CachingAssetBundle {
  _Catalog(this.source);
  final String source;
  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(source);
}

class _Photos extends PhotoService {
  @override
  Future<XFile?> recover() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ids = [
    'project_01',
    'project_03',
    'project_15',
    'project_38',
    'project_39',
  ];
  late String source;
  late List<UpcyclingProject> catalog;
  UpcyclingProject recipe(String id) => catalog.singleWhere((p) => p.id == id);
  setUpAll(() async {
    source = await rootBundle.loadString(RecipeRepository.assetPath);
    catalog = RecipeRepository.parse(source);
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> app(
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
        bundle: _Catalog(source),
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: reduced,
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: home,
          ),
        ),
      ),
    );
    if (reduced) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> press(
    WidgetTester tester,
    Finder target, {
    bool settle = true,
  }) async {
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('.dart_tool/package1/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  test('Package 1 retains 22 catalogue steps in the shared registry', () {
    expect(WorkshopSteps.recipes.keys.toSet(), {
      'project_49',
      'project_45',
      'project_46',
      'project_41',
      'project_42',
      'project_43',
      'project_47',
      ...ids,
      ...['project_19', 'project_26', 'project_48', 'project_44'],
    });
    expect([for (final id in ids) recipe(id).steps.length], [5, 4, 5, 4, 4]);
    for (final id in ids) {
      final p = recipe(id);
      expect(WorkshopSteps.supports(p), isTrue);
      expect(WorkshopSteps.resolve(p, -1), isNull);
      expect(WorkshopSteps.resolve(p, p.steps.length), isNull);
      for (var i = 0; i < p.steps.length; i++) {
        final step = WorkshopSteps.resolve(p, i)!;
        expect(step.description, isNotEmpty);
        expect(step.parts.map((p) => p.id).toSet().length, step.parts.length);
        final partIds = step.parts.map((p) => p.id).toSet();
        for (final clip in step.sequence.clips) {
          expect(partIds.containsAll(clip.targets.keys), isTrue);
        }
      }
    }
    for (final p in catalog.where(
      (p) => !{
        'project_49',
        'project_45',
        'project_46',
        'project_41',
        'project_42',
        'project_43',
        'project_47',
        ...ids,
        ...['project_19', 'project_26', 'project_48', 'project_44'],
      }.contains(p.id),
    )) {
      expect(WorkshopSteps.supports(p), isFalse);
    }
    expect(
      WorkshopSteps.recipes['project_01']![1].parts
          .where((p) => p.object == WorkshopObject.roll)
          .length,
      3,
    );
    expect(
      WorkshopSteps.recipes['project_03']![2].parts
          .where((p) => p.object == WorkshopObject.cap)
          .length,
      10,
    );
    expect(WorkshopSteps.recipes['project_15']![2].parts.length, 6);
    expect(
      WorkshopSteps.recipes['project_39']!.last.description,
      contains('silgili'),
    );
  });

  for (final id in ids) {
    testWidgets(
      '$id opens from Home / Projects, traverses real steps and finishes back to list',
      (tester) async {
        final p = recipe(id);
        final boundary = GlobalKey();
        await app(
          tester,
          HomeScreen(photoService: _Photos()),
          boundary: boundary,
        );
        await press(
          tester,
          find.widgetWithText(NavigationDestination, 'Projeler'),
        );
        final card = find.byKey(ValueKey('project-card-$id'));
        await tester.scrollUntilVisible(card, 300, maxScrolls: 70);
        await press(
          tester,
          find.descendant(of: card, matching: find.text(p.name)),
        );
        expect(find.byType(ProjectDetailScreen), findsOneWidget);
        expect(find.byType(RecipeMotionPlayer), findsNothing);
        await press(tester, find.byKey(const Key('start-building')));
        expect(find.byType(WorkshopRecipeGuide), findsOneWidget);
        if (id == 'project_01') {
          final player = tester.state(find.byType(RecipeMotionPlayer));
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(player.mounted, isFalse);
          expect(find.byType(ProjectDetailScreen), findsOneWidget);
          await press(tester, find.byKey(const Key('start-building')));
          expect(find.text('Adım 1 / 5'), findsOneWidget);
        }
        for (var i = 0; i < p.steps.length; i++) {
          final step = WorkshopSteps.resolve(p, i)!;
          final actual = tester.widget<RecipeStepCard>(
            find.byType(RecipeStepCard),
          );
          expect(actual.number, i + 1);
          expect(actual.total, p.steps.length);
          expect(actual.text, p.steps[i]);
          expect(find.text(step.description), findsOneWidget);
          expect(find.text(p.steps[i]), findsNothing);
          expect(find.byType(WorkshopStepScene), findsOneWidget);
          if (step.warning != null) {
            expect(find.text(step.warning!), findsOneWidget);
          }
          if (i < p.steps.length - 1) {
            await press(tester, find.byKey(const Key('next-step')));
          }
        }
        if (const bool.fromEnvironment('PACKAGE1_PREVIEW')) {
          final context = tester.element(find.byType(RecipeStepViewer));
          await Scrollable.ensureVisible(context, alignment: 0);
          await tester.pumpAndSettle();
          await capture(tester, boundary, 'previews/$id');
        }
        await press(tester, find.byKey(const Key('previous-step')));
        expect(
          tester.widget<RecipeStepCard>(find.byType(RecipeStepCard)).number,
          p.steps.length - 1,
        );
        await press(tester, find.byKey(const Key('next-step')));
        expect(find.text('Bitir'), findsOneWidget);
        await press(tester, find.byKey(const Key('next-step')));
        expect(find.text('Projen hazır!'), findsOneWidget);
        expect(find.byType(RecipeMotionPlayer), findsNothing);
        await press(tester, find.byKey(const Key('return-to-recipes')));
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(ProjectCard), findsWidgets);
        expect(find.byType(ProjectDetailScreen), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Playback auto starts, repeats, pauses/resumes and resets on step change',
    (tester) async {
      final p = recipe('project_01');
      await app(tester, WorkshopRecipeGuide(project: p), reduced: false);
      final first = tester.state(find.byType(RecipeMotionPlayer));
      final step = WorkshopSteps.resolve(p, 0)!;
      await tester.pump(const Duration(milliseconds: 1000));
      final a = tester
          .widget<WorkshopStepScene>(find.byType(WorkshopStepScene))
          .frame['flap'];
      await tester.pump(step.sequence.duration);
      final b = tester
          .widget<WorkshopStepScene>(find.byType(WorkshopStepScene))
          .frame['flap'];
      expect((a.offset - b.offset).distance, lessThan(.01));
      await press(
        tester,
        find.byKey(const Key('motion-playback')),
        settle: false,
      );
      final paused = tester
          .widget<WorkshopStepScene>(find.byType(WorkshopStepScene))
          .frame['flap'];
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester
            .widget<WorkshopStepScene>(find.byType(WorkshopStepScene))
            .frame['flap']
            .offset,
        paused.offset,
      );
      await press(
        tester,
        find.byKey(const Key('motion-playback')),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester
            .widget<WorkshopStepScene>(find.byType(WorkshopStepScene))
            .frame['flap']
            .offset,
        isNot(paused.offset),
      );
      await press(tester, find.byKey(const Key('next-step')), settle: false);
      expect(first.mounted, isFalse);
      expect(
        tester
            .widget<WorkshopStepScene>(find.byType(WorkshopStepScene))
            .frame['roll0']
            .offset,
        const Offset(0, -100),
      );
      for (var i = 2; i < p.steps.length; i++) {
        await press(tester, find.byKey(const Key('next-step')), settle: false);
      }
      final lastPlayer = tester.state(find.byType(RecipeMotionPlayer));
      final finish = find.byKey(const Key('next-step'));
      await tester.ensureVisible(finish);
      await tester.pump();
      await tester.tap(finish);
      await tester.tap(finish);
      await tester.pump();
      expect(lastPlayer.mounted, isFalse);
      await tester.pumpAndSettle();
      expect(find.byType(WorkshopCompleteScreen), findsOneWidget);
      expect(find.text('Projen hazır!'), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Media fallback keeps short instructions and relevant warnings', (
    tester,
  ) async {
    final p = recipe('project_39');
    await app(
      tester,
      WorkshopRecipeGuide(project: p, mediaBuilder: (_, _, _) => null),
    );
    for (var i = 0; i < p.steps.length - 1; i++) {
      await press(tester, find.byKey(const Key('next-step')));
    }
    expect(find.text(WorkshopSteps.resolve(p, 3)!.description), findsOneWidget);
    expect(find.text(WorkshopSteps.resolve(p, 3)!.warning!), findsOneWidget);
    expect(find.byType(RecipeMotionPlayer), findsNothing);
  });

  for (final config in [
    (const Size(320, 640), 2.0),
    (const Size(640, 360), 1.5),
  ]) {
    testWidgets(
      'All 26 steps and completion fit ${config.$1} text ${config.$2}',
      (tester) async {
        for (final id in ids) {
          final p = recipe(id);
          await app(
            tester,
            WorkshopRecipeGuide(key: ValueKey(id), project: p),
            size: config.$1,
            scale: config.$2,
          );
          for (var i = 0; i < p.steps.length; i++) {
            expect(tester.takeException(), isNull);
            await press(tester, find.byKey(const Key('next-step')));
          }
          expect(find.text('Projen hazır!'), findsOneWidget);
          await tester.ensureVisible(
            find.byKey(const Key('return-to-recipes')),
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      },
    );
  }

  testWidgets('Optional real Flutter animated organizer preview', (
    tester,
  ) async {
    if (!const bool.fromEnvironment('PACKAGE1_PREVIEW')) return;
    final boundary = GlobalKey();
    await app(
      tester,
      WorkshopRecipeGuide(project: recipe('project_01')),
      reduced: false,
      boundary: boundary,
    );
    await press(tester, find.byKey(const Key('next-step')), settle: false);
    for (var frame = 0; frame < 50; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
      await capture(
        tester,
        boundary,
        'frames/organizer-${frame.toString().padLeft(3, '0')}',
      );
    }
    await tester.pumpWidget(const SizedBox());
  });
}
