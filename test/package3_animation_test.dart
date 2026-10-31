import 'dart:io';
import 'dart:convert';

import 'package:hackathon_projesi/animations/pet_planter_steps.dart';
import 'package:hackathon_projesi/animations/motion_sequence.dart';

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
    'project_45',
    'project_46',
    'project_41',
    'project_42',
    'project_43',
    'project_47',
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
      final file = File('.dart_tool/package3/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  test(
    'All 17 recipes resolve; Package 3 follows all 34 real ordered steps',
    () {
      expect(WorkshopSteps.recipes.length, 16);
      expect({
        ...WorkshopSteps.recipes.keys,
        'project_40',
      }, catalog.map((p) => p.id).toSet());
      expect(
        [for (final id in ids) recipe(id).steps.length],
        [6, 6, 5, 5, 6, 6],
      );
      for (final p in catalog) {
        for (var i = 0; i < p.steps.length; i++) {
          if (p.id == 'project_40') {
            expect(PetPlanterSteps.resolve(p, i), isNotNull);
            continue;
          }
          final step = WorkshopSteps.resolve(p, i)!;
          expect(step.description, isNotEmpty);
          final partIds = step.parts.map((p) => p.id).toSet();
          expect(partIds.length, step.parts.length);
          for (final clip in step.sequence.clips) {
            expect(partIds.containsAll(clip.targets.keys), isTrue);
          }
        }
        expect(WorkshopSteps.resolve(p, -1), isNull);
        expect(WorkshopSteps.resolve(p, p.steps.length), isNull);
      }
      final raw = (jsonDecode(source)['projects'] as List).firstWhere(
        (p) => p['id'] == 'project_41',
      ) as Map<String, dynamic>;
      final changed = UpcyclingProject.fromJson({
        ...raw,
        'steps': [...raw['steps'], 'Additional test-only step'],
      });
      expect(WorkshopSteps.resolve(changed, 0), isNull);
      final strips = WorkshopSteps.resolve(recipe('project_46'), 3)!.parts;
      expect(strips.length, 4);
      expect(strips.where((p) => p.label == 'top').length, 2);
      expect(strips.where((p) => p.label == 'bottom').length, 2);
      final joint = WorkshopSteps.resolve(recipe('project_46'), 4)!;
      expect(joint.sequence.sample(0)['joint'].amount, 1);
      expect(joint.sequence.sample(1)['joint'].amount, 2);
      expect(joint.sequence.sample(1)['grid'].amount, 1);
      final threaded = WorkshopSteps.resolve(recipe('project_41'), 2)!;
      final folded = WorkshopSteps.resolve(recipe('project_41'), 3)!;
      expect(threaded.sequence.sample(1)['mouth'].amount, 2);
      expect(folded.sequence.sample(1)['mouth'].amount, 3);
      expect(folded.sequence.sample(1)['cap'].offset, Offset.zero);
      final basket = WorkshopSteps.resolve(recipe('project_43'), 3)!;
      expect(
        basket.parts
            .where((p) => p.object == WorkshopObject.suspensionRope)
            .length,
        3,
      );
      expect(
        WorkshopSteps.resolve(recipe('project_43'), 4)!.description,
        contains('300'),
      );
      final funnel = WorkshopSteps.recipes['project_42']!;
      expect(
        funnel.last.parts.any((p) => p.object == WorkshopObject.dryStream),
        isTrue,
      );
      final funnelTop = funnel.last.parts.singleWhere((p) => p.id == 'top');
      final nozzle = transformMotionPoint(
        const Offset(0, -66),
        Offset.zero,
        MotionPose(offset: funnelTop.position, angle: funnelTop.angle),
      );
      final receiver = funnel.last.parts.singleWhere((p) => p.id == 'receiver');
      expect(
        nozzle.dy,
        inInclusiveRange(
          receiver.position.dy - 48 * receiver.scale,
          receiver.position.dy - 26 * receiver.scale,
        ),
      );
      expect(
        funnel
            .expand((s) => s.parts)
            .any(
              (p) =>
                  p.object == WorkshopObject.water ||
                  p.object == WorkshopObject.liquidFill,
            ),
        isFalse,
      );
      final trap = WorkshopSteps.resolve(recipe('project_47'), 0)!;
      expect(
        trap.parts.where((p) => p.object == WorkshopObject.singleDrop).length,
        1,
      );
      expect(trap.description, contains('50 ml'));
      expect(trap.description, contains('bir damla'));
    },
  );

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
        if (id == 'project_41') {
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
        if (const bool.fromEnvironment('PACKAGE3_PREVIEW')) {
          final previewIndex =
              {'project_46': 4, 'project_41': 3, 'project_43': 4}[id] ??
              p.steps.length - 1;
          for (var i = p.steps.length - 1; i > previewIndex; i--) {
            await press(tester, find.byKey(const Key('previous-step')));
          }

          final context = tester.element(find.byType(RecipeStepViewer));
          await Scrollable.ensureVisible(context, alignment: 0);
          await tester.pumpAndSettle();
          await capture(tester, boundary, 'previews/$id');
          for (var i = previewIndex; i < p.steps.length - 1; i++) {
            await press(tester, find.byKey(const Key('next-step')));
          }
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
      final p = recipe('project_41');
      await app(tester, WorkshopRecipeGuide(project: p), reduced: false);
      final first = tester.state(find.byType(RecipeMotionPlayer));
      final step = WorkshopSteps.resolve(p, 0)!;
      await tester.pump(const Duration(milliseconds: 1000));
      final a = tester
          .widget<WorkshopStepScene>(find.byType(WorkshopStepScene))
          .frame['mark'];
      await tester.pump(step.sequence.duration);
      final b = tester
          .widget<WorkshopStepScene>(find.byType(WorkshopStepScene))
          .frame['mark'];
      expect((a.amount - b.amount).abs(), lessThan(.01));
      await press(
        tester,
        find.byKey(const Key('motion-playback')),
        settle: false,
      );
      final paused = tester
          .widget<WorkshopStepScene>(find.byType(WorkshopStepScene))
          .frame['mark'];
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester
            .widget<WorkshopStepScene>(find.byType(WorkshopStepScene))
            .frame['mark']
            .amount,
        paused.amount,
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
            .frame['mark']
            .amount,
        isNot(paused.amount),
      );
      await press(tester, find.byKey(const Key('next-step')), settle: false);
      expect(first.mounted, isFalse);
      expect(
        tester
            .widget<WorkshopStepScene>(find.byType(WorkshopStepScene))
            .frame['band']
            .amount,
        0,
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
    final p = recipe('project_43');
    await app(
      tester,
      WorkshopRecipeGuide(project: p, mediaBuilder: (_, _, _) => null),
    );
    for (var i = 0; i < p.steps.length - 1; i++) {
      await press(tester, find.byKey(const Key('next-step')));
    }
    expect(find.text(WorkshopSteps.resolve(p, 5)!.description), findsOneWidget);
    expect(find.text(WorkshopSteps.resolve(p, 5)!.warning!), findsOneWidget);
    expect(find.byType(RecipeMotionPlayer), findsNothing);
  });

  for (final config in [
    (const Size(320, 640), 2.0),
    (const Size(640, 360), 1.5),
  ]) {
    testWidgets(
      'All 34 steps and completion fit ${config.$1} text ${config.$2}',
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

  for (final preview in [
    ('project_46', 4, 65, 'grid'),
    ('project_41', 2, 120, 'bag-clip'),
  ]) {
    testWidgets('Optional real Flutter ${preview.$4} animation preview', (
      tester,
    ) async {
      if (!const bool.fromEnvironment('PACKAGE3_PREVIEW')) return;
      final boundary = GlobalKey();
      await app(
        tester,
        WorkshopRecipeGuide(project: recipe(preview.$1)),
        reduced: false,
        boundary: boundary,
      );
      for (var i = 0; i < preview.$2; i++) {
        await press(tester, find.byKey(const Key('next-step')), settle: false);
      }
      for (var frame = 0; frame < preview.$3; frame++) {
        if (preview.$1 == 'project_41' && frame == 60) {
          await press(
            tester,
            find.byKey(const Key('next-step')),
            settle: false,
          );
        }
        await tester.pump(const Duration(milliseconds: 100));
        await capture(
          tester,
          boundary,
          'frames/${preview.$4}-${frame.toString().padLeft(3, '0')}',
        );
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Step expansions are removed and measurements stay in summary', (
    tester,
  ) async {
    final p = recipe('project_41');
    await app(tester, WorkshopRecipeGuide(project: p));
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.text(WorkshopSteps.resolve(p, 0)!.description), findsOneWidget);
    expect(WorkshopSteps.resolve(p, 0)!.description, contains('2–3 cm'));
  });

  testWidgets('Unregistered recipes retain the original text fallback', (
    tester,
  ) async {
    final raw =
        (jsonDecode(source)['projects'] as List).first as Map<String, dynamic>;
    final p = UpcyclingProject.fromJson({
      ...raw,
      'id': 'unsupported-test-only',
    });
    await app(tester, WorkshopRecipeGuide(project: p));
    expect(find.text(p.steps.first), findsOneWidget);
    expect(find.byType(RecipeMotionPlayer), findsNothing);
  });
}
