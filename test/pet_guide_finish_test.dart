import 'helpers/mock_photo_platform.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_projesi/core/app_theme.dart';
import 'package:hackathon_projesi/core/pet_guide_copy.dart';
import 'package:hackathon_projesi/models/upcycling_project.dart';
import 'package:hackathon_projesi/screens/pet_guide_complete_screen.dart';
import 'package:hackathon_projesi/screens/pet_project_detail_screen.dart';
import 'package:hackathon_projesi/screens/home_screen.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';
import 'package:hackathon_projesi/widgets/recipe_motion_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(mockPhotoPlatform);
  late UpcyclingProject planter;
  late HomeTestAssets homeAssets;
  setUpAll(() async {
    final source = await rootBundle.loadString(RecipeRepository.assetPath);
    homeAssets = HomeTestAssets(source);
    planter = RecipeRepository.parse(source)
        .singleWhere((p) => p.id == 'project_40');
  });

  Future<void> app(
    WidgetTester tester,
    Widget home, {
    bool reduced = true,
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: homeAssets,
        child: MaterialApp(
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
    );
    await tester.pump();
  }

  Future<void> press(WidgetTester tester, Key key, {bool settle = true}) async {
    final button = find.byKey(key);
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    if (settle) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> lastStep(WidgetTester tester, {bool settle = true}) async {
    for (var i = 0; i < 5; i++) {
      await press(tester, const Key('next-step'), settle: settle);
    }
    expect(find.text('Adım 6 / 6'), findsOneWidget);
    expect(find.text('Bitir'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('next-step'))).onPressed,
      isNotNull,
    );
  }

  Widget source() => Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => PetProjectDetailScreen(project: planter),
          ),
        ),
        child: const Text('Tarif listesi — mevcut filtre'),
      ),
    ),
  );

  testWidgets(
    'Six short summaries appear once; only risky steps show warnings',
    (tester) async {
      await app(tester, PetRecipeGuide(project: planter));
      for (var i = 0; i < 6; i++) {
        expect(find.text(PetGuideCopy.steps[i]), findsOneWidget);
        expect(find.text(planter.steps[i]), findsNothing);
        for (var warning in [
          PetGuideCopy.cuttingWarning,
          PetGuideCopy.holeWarning,
        ]) {
          expect(
            find.text(warning),
            PetGuideCopy.warnings[i] == warning ? findsOneWidget : findsNothing,
          );
        }
        final visibleText = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .join(' ')
            .toLowerCase();
        expect(visibleText, isNot(contains('fitil')));
        expect(visibleText, isNot(contains('hazne')));
        expect(visibleText, isNot(contains('çapak')));
        expect(visibleText, isNot(contains('matkap')));
        if (i < 5) await press(tester, const Key('next-step'));
      }
      await press(tester, const Key('previous-step'));
      expect(find.text(PetGuideCopy.step5), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Cloth measurements remain in main step without expansion', (
    tester,
  ) async {
    await app(tester, PetRecipeGuide(project: planter));
    await press(tester, const Key('next-step'));
    await press(tester, const Key('next-step'));
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.text(PetGuideCopy.step3), findsOneWidget);
    expect(PetGuideCopy.step3, contains('25 cm'));
    expect(PetGuideCopy.step3, contains('10 cm'));
  });

  testWidgets(
    'Finish disposes running player before navigation and ignores double tap',
    (tester) async {
      await app(tester, PetRecipeGuide(project: planter), reduced: false);
      await tester.pump(const Duration(milliseconds: 500));
      await lastStep(tester, settle: false);
      final playerState = tester.state(find.byType(RecipeMotionPlayer));
      final finish = find.byKey(const Key('next-step'));
      await tester.ensureVisible(finish);
      await tester.pump();
      await tester.tap(finish);
      await tester.tap(finish);
      await tester.pump();
      expect(playerState.mounted, isFalse);
      await tester.pumpAndSettle();
      expect(find.byType(PetGuideCompleteScreen), findsOneWidget);
      expect(find.text('Harika İş Çıkardın! 🌱'), findsOneWidget);
      expect(find.byType(RecipeMotionPlayer), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Return home clears the originating list and completed project', (
    tester,
  ) async {
    await app(tester, source());
    await tester.tap(find.text('Tarif listesi — mevcut filtre'));
    await tester.pumpAndSettle();
    await press(tester, const Key('start-building'));
    await lastStep(tester);
    await press(tester, const Key('next-step'));
    await press(tester, const Key('return-to-home'));
    expect(find.text('Tarif listesi — mevcut filtre'), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(HomeScreen))).canPop(),
      isFalse,
    );
    expect(find.byType(PetProjectDetailScreen), findsNothing);
    expect(find.byType(PetGuideCompleteScreen), findsNothing);
    expect(find.byType(RecipeMotionPlayer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'System back from completion returns home without a project underneath',
    (tester) async {
      await app(tester, source());
      await tester.tap(find.text('Tarif listesi — mevcut filtre'));
      await tester.pumpAndSettle();
      await press(tester, const Key('start-building'));
      await lastStep(tester);
      await press(tester, const Key('next-step'));
      await tester.binding.handlePopRoute();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(PetProjectDetailScreen), findsNothing);
      expect(find.byType(RecipeMotionPlayer), findsNothing);
      expect(
        Navigator.of(tester.element(find.byType(HomeScreen))).canPop(),
        isFalse,
      );
      await tester.binding.handlePopRoute();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.byType(PetGuideCompleteScreen), findsNothing);
      expect(find.byType(PetProjectDetailScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final sample in [
    (const Size(320, 640), 2.0),
    (const Size(640, 360), 1.5),
  ]) {
    testWidgets('Finish and completion fit ${sample.$1} text ${sample.$2}', (
      tester,
    ) async {
      await app(
        tester,
        PetRecipeGuide(project: planter),
        size: sample.$1,
        scale: sample.$2,
      );
      await lastStep(tester);
      await press(tester, const Key('next-step'));
      expect(find.text('Harika İş Çıkardın! 🌱'), findsOneWidget);
      final button = find.byKey(const Key('return-to-home'));
      await tester.ensureVisible(button);
      await tester.pump();
      expect(button.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
