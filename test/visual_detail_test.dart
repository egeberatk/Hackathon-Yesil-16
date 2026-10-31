import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hackathon_projesi/core/app_theme.dart';
import 'package:hackathon_projesi/core/pet_guide_copy.dart';
import 'package:hackathon_projesi/models/material_item.dart';
import 'package:hackathon_projesi/models/upcycling_project.dart';
import 'package:hackathon_projesi/screens/home_screen.dart';
import 'package:hackathon_projesi/screens/project_detail_screen.dart';
import 'package:hackathon_projesi/screens/pet_project_detail_screen.dart';
import 'package:hackathon_projesi/screens/photo_preview_screen.dart';
import 'package:hackathon_projesi/services/photo_service.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';
import 'package:hackathon_projesi/services/recipe_matching_service.dart';
import 'package:hackathon_projesi/widgets/recipe_icon_grid.dart';
import 'package:hackathon_projesi/widgets/recipe_detail_layout.dart';
import 'package:hackathon_projesi/widgets/recipe_step_card.dart';
import 'package:hackathon_projesi/widgets/recipe_step_viewer.dart';
import 'package:hackathon_projesi/widgets/workshop_vector_icon.dart';

class VisualAssets extends CachingAssetBundle {
  VisualAssets(this.source);
  final String source;
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(source);
  @override
  Future<ByteData> load(String key) => throw UnsupportedError(key);
}

class VisualPhotos extends PhotoService {
  final sources = <ImageSource>[];
  XFile? next;
  Object? error;
  Completer<XFile?>? pending;
  @override
  Future<XFile?> recover() async => null;
  @override
  Future<XFile?> pick(ImageSource source) async {
    sources.add(source);
    if (error != null) throw error!;
    return pending == null ? next : pending!.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String source;
  late List<UpcyclingProject> catalog;
  late UpcyclingProject project;
  setUpAll(() async {
    source = await rootBundle.loadString(RecipeRepository.assetPath);
    catalog = RecipeRepository.parse(source);
    project = catalog.singleWhere((p) => p.id == 'project_40');
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  RecipeMatch matched(List<MaterialItem> items) => RecipeMatchingService.match(
    catalog,
    items,
  ).singleWhere((m) => m.project.id == project.id);
  RecipeMatch ready() => matched([
    MaterialItem(type: WasteType.plastic),
    MaterialItem(type: WasteType.plasticCap),
  ]);
  Future<void> app(
    WidgetTester tester,
    Widget screen, {
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
        bundle: VisualAssets(source),
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: screen,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'PET overview shows data quantities, accessible tap tooltips and short readiness',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await app(tester, ProjectDetailScreen(project: project, match: ready()));
      expect(find.text('Bu projeyi yapabilirsin!'), findsOneWidget);
      expect(find.byType(RecipeStepViewer), findsNothing);
      expect(find.text(project.practicalUse).hitTestable(), findsNothing);
      final grid = find.byKey(const Key('required-material-icons'));
      final tiles = find.descendant(
        of: grid,
        matching: find.byType(RecipeIconTile),
      );
      expect(tiles, findsNWidgets(project.requiredMaterials.length));
      final first = tester.widget<RecipeIconTile>(tiles.first).item;
      expect(first.name, project.requiredMaterials.first.name);
      expect(first.caption, '${project.requiredMaterials.first.quantity} adet');
      expect(find.bySemanticsLabel(RegExp('1,5.*PET şişe')), findsOneWidget);
      semantics.dispose();
      await tap(tester, tiles.first);
      expect(find.text('${first.name}\n${first.caption}'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      final supplies = tester
          .widgetList<RecipeIconTile>(
            find.descendant(
              of: find.byKey(const Key('required-supply-icons')),
              matching: find.byType(RecipeIconTile),
            ),
          )
          .map((tile) => tile.item)
          .toList();
      expect(supplies.any((item) => item.name.contains('fitil')), isFalse);
      expect(
        supplies.any((item) => item.kind == WorkshopIconKind.drill),
        isFalse,
      );
      expect(
        supplies.map((item) => item.kind),
        containsAll([
          WorkshopIconKind.scissors,
          WorkshopIconKind.ruler,
          WorkshopIconKind.pencil,
          WorkshopIconKind.mat,
          WorkshopIconKind.tape,
          WorkshopIconKind.cloth,
        ]),
      );
      await tap(tester, find.byTooltip('Güvenlik uyarısı'));
      expect(find.text(PetGuideCopy.safety), findsOneWidget);
      await tap(tester, find.text('Kapat'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Missing icons use the original matching result and exact missing amount',
    (tester) async {
      final match = matched([MaterialItem(type: WasteType.plastic)]);
      await app(tester, ProjectDetailScreen(project: project, match: match));
      final tiles = tester
          .widgetList<RecipeIconTile>(
            find.descendant(
              of: find.byKey(const Key('missing-material-icons')),
              matching: find.byType(RecipeIconTile),
            ),
          )
          .toList();
      expect(tiles.length, match.missingMaterials.length);
      expect(tiles.single.item.name, match.missingMaterials.single.name);
      expect(
        tiles.single.item.caption,
        '${match.missingMaterials.single.quantity} eksik',
      );
      expect(find.text('Bu projeyi yapabilirsin!'), findsNothing);
    },
  );

  testWidgets(
    'Start opens the unchanged six-step guide and back returns to the overview',
    (tester) async {
      await app(tester, ProjectDetailScreen(project: project));
      await tap(tester, find.byKey(const Key('start-building')));
      expect(find.byType(PetRecipeGuide), findsOneWidget);
      for (var i = 0; i < project.steps.length; i++) {
        expect(
          tester.widget<RecipeStepCard>(find.byType(RecipeStepCard)).text,
          project.steps[i],
        );
        if (i < project.steps.length - 1) {
          await tap(tester, find.byKey(const Key('next-step')));
        }
      }
      await tap(tester, find.byType(BackButton));
      expect(find.byType(PetProjectDetailScreen), findsOneWidget);
      expect(find.byKey(const Key('start-building')), findsOneWidget);
    },
  );

  testWidgets(
    'Remaining final-package recipes keep shared overview and original step text',
    (tester) async {
      for (final other in catalog.where(
        (p) => const {
          'project_45',
          'project_46',
          'project_41',
          'project_42',
          'project_43',
          'project_47',
        }.contains(p.id),
      )) {
        await app(tester, ProjectDetailScreen(project: other));
        expect(find.byType(PetProjectDetailScreen), findsNothing);
        expect(find.byType(RecipeDetailLayout), findsOneWidget);
        expect(find.byType(RecipeStepViewer), findsNothing);
        await tap(tester, find.byKey(const Key('start-building')));
        expect(find.byType(RecipeStepViewer), findsOneWidget);
        expect(
          tester.widget<RecipeStepCard>(find.byType(RecipeStepCard)).text,
          other.steps.first,
        );
        await tap(tester, find.byType(BackButton));
      }
    },
  );

  for (final config in [
    (const Size(320, 640), 2.0),
    (const Size(640, 360), 1.5),
  ]) {
    testWidgets(
      'Visual overview, tooltips, safety and guide fit ${config.$1} scale ${config.$2}',
      (tester) async {
        await app(
          tester,
          ProjectDetailScreen(project: project, match: ready()),
          size: config.$1,
          scale: config.$2,
        );
        expect(
          tester.getSize(find.byKey(const Key('start-building'))).height,
          greaterThanOrEqualTo(56),
        );
        await tester.ensureVisible(
          find.byKey(const Key('required-supply-icons')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tap(tester, find.byTooltip('Güvenlik uyarısı'));
        expect(find.text(PetGuideCopy.safety), findsOneWidget);
        await tap(tester, find.text('Kapat'));
        await tap(tester, find.byKey(const Key('start-building')));
        await tap(tester, find.byKey(const Key('next-step')));
        expect(
          tester.widget<RecipeStepCard>(find.byType(RecipeStepCard)).number,
          2,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final selectedSource in ImageSource.values) {
    testWidgets(
      'Direct ${selectedSource.name} selection previews without starting analysis',
      (tester) async {
        final photos = VisualPhotos()
          ..next = XFile.fromData(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
            ),
            name: 'test.png',
          );
        await app(tester, HomeScreen(photoService: photos));
        await tap(
          tester,
          find.text(
            selectedSource == ImageSource.camera
                ? 'Atığını Tara'
                : 'Galeriden seç',
          ),
        );
        expect(photos.sources, [selectedSource]);
        expect(find.byType(BottomSheet), findsNothing);
        expect(
          tester
              .widget<PhotoPreviewScreen>(find.byType(PhotoPreviewScreen))
              .photo,
          same(photos.next),
        );
        expect(find.widgetWithText(FilledButton, 'Analiz Et'), findsOneWidget);
        expect(find.text('Analiz sürüyor'), findsNothing);
        await tap(tester, find.byTooltip('Geri'));
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );
  }

  testWidgets(
    'Camera permission error is readable and a second same-frame tap is guarded',
    (tester) async {
      final photos = VisualPhotos()
        ..error = PlatformException(code: 'camera_access_denied');
      await app(tester, HomeScreen(photoService: photos));
      await tap(tester, find.text('Atığını Tara'));
      expect(find.textContaining('iznini'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      photos.error = null;
      photos.pending = Completer<XFile?>();
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Atığını Tara'),
      );
      button.onPressed!();
      button.onPressed!();
      await tester.pump();
      expect(photos.sources, [ImageSource.camera, ImageSource.camera]);
      photos.pending!.complete(null);
      await tester.pumpAndSettle();
      expect(find.byType(PhotoPreviewScreen), findsNothing);
    },
  );

  testWidgets('Optional real Flutter overview screenshots', (tester) async {
    if (!const bool.fromEnvironment('VISUAL_DETAIL_PREVIEW')) return;
    final boundary = GlobalKey();
    await app(
      tester,
      ProjectDetailScreen(project: project, match: ready()),
      boundary: boundary,
    );
    Future<void> capture(String name) async => tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('.dart_tool/design-preview/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await capture('pet-visual-detail');
    await tester.ensureVisible(find.byKey(const Key('required-supply-icons')));
    await tester.pumpAndSettle();
    await capture('pet-visual-tools');
  });
}
