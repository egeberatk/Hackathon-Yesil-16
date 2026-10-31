import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_projesi/core/app_theme.dart';
import 'package:hackathon_projesi/models/material_item.dart';
import 'package:hackathon_projesi/models/upcycling_project.dart';
import 'package:hackathon_projesi/screens/material_confirmation_screen.dart';
import 'package:hackathon_projesi/screens/project_detail_screen.dart';
import 'package:hackathon_projesi/screens/projects_screen.dart';
import 'package:hackathon_projesi/services/recipe_photo_repository.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';
import 'package:hackathon_projesi/widgets/material_card.dart';
import 'package:hackathon_projesi/widgets/material_type_picker.dart';
import 'package:hackathon_projesi/widgets/material_visual.dart';
import 'package:hackathon_projesi/widgets/project_card.dart';
import 'package:hackathon_projesi/widgets/recipe_product_photo.dart';

class _Assets extends CachingAssetBundle {
  _Assets(this.recipes, this.photos, this.binary);
  final String recipes, photos;
  final Map<String, ByteData> binary;
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(
        key == RecipePhotoRepository.assetPath ? photos : recipes,
      );
  @override
  Future<ByteData> load(String key) => binary.containsKey(key)
      ? SynchronousFuture(binary[key]!)
      : rootBundle.load(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<UpcyclingProject> catalog;
  late String recipes, photos;
  final binary = <String, ByteData>{};
  setUpAll(() async {
    catalog = await RecipeRepository().load();
    recipes = await rootBundle.loadString(RecipeRepository.assetPath);
    photos = await rootBundle.loadString(RecipePhotoRepository.assetPath);
    binary['AssetManifest.bin'] = await rootBundle.load('AssetManifest.bin');
    for (final p in catalog) {
      final path = 'assets/recipes/photos/${p.id}.webp';
      binary[path] = await rootBundle.load(path);
    }
    await (FontLoader(
      'PlusJakartaSans',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> app(
    WidgetTester tester,
    Widget child, {
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
          bundle: _Assets(recipes, photos, binary),
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
            home: child,
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  MaterialCard card(WidgetTester tester) =>
      tester.widget<MaterialCard>(find.byType(MaterialCard).first);
  bool enabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(find.byKey(const Key('find-recipes')))
          .onPressed !=
      null;
  Finder stepButton(String tooltip) => find.byWidgetPredicate(
    (widget) => widget is IconButton && widget.tooltip == tooltip,
  );
  Future<void> renderPhotos(WidgetTester tester) async {
    for (
      var i = 0;
      i < 8 && find.byTooltip('AI görseli').evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pumpAndSettle();
    }
  }

  String photoAsset(WidgetTester tester) {
    final provider = tester
        .widget<Image>(find.byKey(const Key('recipe-product-image')))
        .image;
    return ((provider is ResizeImage ? provider.imageProvider : provider)
            as AssetImage)
        .assetName;
  }

  testWidgets(
    'All 17 distinct WebPs decode to 1024 square and exactly match active IDs',
    (tester) async {
      final manifest = jsonDecode(
        File('assets/recipes/photos/generation_manifest.json')
            .readAsStringSync(),
      );
      final ids = catalog.map((p) => p.id).toSet();
      expect(ids, hasLength(17));
      expect((manifest['images'] as Map).keys.toSet(), ids);
      expect(
        (manifest['images'] as Map).values.map((r) => r['sha256']).toSet(),
        hasLength(17),
      );
      expect(
        Directory('assets/recipes/photos')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.webp'))
            .length,
        17,
      );
      for (final p in catalog) {
        final photo = await RecipePhotoRepository(
          bundle: _Assets(recipes, photos, binary),
        ).find(p.id);
        expect(photo?.aiGenerated, isTrue);
        expect(photo?.asset, 'assets/recipes/photos/${p.id}.webp');
        final size = await tester.runAsync(() async {
          final codec = await ui.instantiateImageCodec(
            binary[photo!.asset]!.buffer.asUint8List(),
          );
          final frame = await codec.getNextFrame();
          final result = Size(
            frame.image.width.toDouble(),
            frame.image.height.toDouble(),
          );
          frame.image.dispose();
          codec.dispose();
          return result;
        });
        expect(size, const Size(1024, 1024));
        expect(binary[photo!.asset], isNotNull);
      }
      expect(
        await RecipePhotoRepository(bundle: _Assets(recipes, photos, binary))
            .find('project_02'),
        isNull,
      );
    },
  );

  test(
    'AI metadata cannot pretend to be a licensed real photo or remote asset',
    () {
      final record = {
        'kind': 'ai_generated',
        'asset': 'assets/recipes/photos/project_01.webp',
        'title': 'Masa düzenleyici',
        'generator': 'image_gen',
        'verified': true,
        'matches_recipe': true,
      };
      expect(RecipePhoto.parse(record)!.aiGenerated, isTrue);
      expect(RecipePhoto.parse({...record, 'verified': false}), isNull);
      expect(
        RecipePhoto.parse({
          ...record,
          'asset': 'https://example.org/image.webp',
        }),
        isNull,
      );
      expect(
        RecipePhoto.parse({
          ...record,
          'asset': 'assets/recipes/photos/../secret.webp',
        }),
        isNull,
      );
      expect(RecipePhoto.parse({...record, 'kind': 'real_photo'}), isNull);
    },
  );

  testWidgets(
    'Every card opens a detail using the same ID-specific product photo',
    (tester) async {
      for (final p in catalog) {
        await app(
          tester,
          Scaffold(
            body: SingleChildScrollView(child: ProjectCard(project: p)),
          ),
        );
        expect(photoAsset(tester), 'assets/recipes/photos/${p.id}.webp');
        await press(tester, find.text(p.name));
        expect(find.byType(ProjectDetailScreen), findsOneWidget);
        expect(photoAsset(tester), 'assets/recipes/photos/${p.id}.webp');
        await renderPhotos(tester);
        expect(find.byTooltip('AI görseli'), findsOneWidget);
        final image = tester.widget<Image>(
          find.byKey(const Key('recipe-product-image')),
        );
        expect(image.fit, BoxFit.contain);
        expect(image.semanticLabel, contains('temsili'));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'Detections merge; explicit confirmation and edited quantities survive Back',
    (tester) async {
      final original = [
        MaterialItem(type: WasteType.plastic, quantity: 2),
        MaterialItem(type: WasteType.plastic, quantity: 3),
        MaterialItem(type: WasteType.unknown),
      ];
      await app(tester, MaterialConfirmationScreen(initialItems: original));
      expect(find.text('Malzemelerini Doğrula'), findsOneWidget);
      expect(find.byType(MaterialCard), findsNWidgets(2));
      expect(card(tester).item.quantity, 5);
      expect(original.first.quantity, 2);
      expect(find.byType(MaterialVisual), findsNWidgets(2));
      expect(find.byType(RecipeProductPhoto), findsNothing);
      expect(enabled(tester), isFalse);
      await press(tester, find.text('Onayla'));
      expect(enabled(tester), isTrue);
      await press(tester, find.byTooltip('Miktarı artır').first);
      expect(card(tester).item.quantity, 6);
      expect(enabled(tester), isFalse);
      await press(tester, find.text('Onayla'));
      await press(tester, find.byKey(const Key('find-recipes')));
      final items = tester
          .widget<ProjectsScreen>(find.byType(ProjectsScreen))
          .items;
      expect(items.single.quantity, 6);
      expect(items.single.requiresConfirmation, isFalse);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(card(tester).item.quantity, 6);
      expect(enabled(tester), isTrue);
    },
  );

  testWidgets(
    'Search and quantity selection add to existing material without duplicate cards',
    (tester) async {
      await app(
        tester,
        MaterialConfirmationScreen(
          initialItems: [
            MaterialItem(type: WasteType.yogurtContainer, quantity: 2),
          ],
        ),
      );
      await press(tester, find.byKey(const Key('add-material')));
      expect(find.byType(MaterialTypePicker), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('material-search')),
        'YOĞURT',
      );
      await tester.pumpAndSettle();
      await press(tester, find.byTooltip('Miktarı artır').last);
      await press(
        tester,
        find.byKey(const ValueKey('pick-material-yogurt_container')),
      );
      expect(find.byType(MaterialCard), findsOneWidget);
      expect(card(tester).item.quantity, 4);
      expect(enabled(tester), isFalse);
      await press(tester, find.text('Onayla'));
      await press(tester, find.byTooltip('Malzemeyi sil'));
      expect(enabled(tester), isFalse);
      expect(find.byType(MaterialCard), findsNothing);
    },
  );

  testWidgets(
    'Count bounds reject overflow; merging never silently discards quantities',
    (tester) async {
      await app(
        tester,
        MaterialConfirmationScreen(
          initialItems: [MaterialItem(type: WasteType.plastic, quantity: 999)],
        ),
      );
      expect(
        tester.widget<IconButton>(stepButton('Miktarı artır')).onPressed,
        isNull,
      );
      await press(tester, find.byKey(const Key('add-material')));
      await press(
        tester,
        find.byKey(const ValueKey('pick-material-pet_bottle')),
      );
      expect(card(tester).item.quantity, 999);
      expect(find.textContaining('999’u geçemez'), findsOneWidget);
      await app(
        tester,
        MaterialConfirmationScreen(
          key: const ValueKey('overflow'),
          initialItems: [
            MaterialItem(type: WasteType.plastic, quantity: 600),
            MaterialItem(type: WasteType.plastic, quantity: 600),
          ],
        ),
      );
      expect(card(tester).item.quantity, 1200);
      expect(enabled(tester), isFalse);
      await press(tester, find.byTooltip('Miktarı azalt'));
      expect(card(tester).item.quantity, 1199);
      await press(tester, find.byTooltip('Malzemeyi düzenle'));
      await tester.enterText(find.byKey(const Key('material-quantity')), '1');
      await press(tester, find.text('Kaydet'));
      expect(card(tester).item.quantity, 1);
      expect(
        tester.widget<IconButton>(stepButton('Miktarı azalt')).onPressed,
        isNull,
      );
      expect(enabled(tester), isTrue);
    },
  );

  for (final config in [
    (const Size(320, 640), 2.0),
    (const Size(640, 360), 1.5),
  ]) {
    testWidgets(
      'Confirmation, searchable picker and photos fit ${config.$1} scale ${config.$2}',
      (tester) async {
        await app(
          tester,
          MaterialConfirmationScreen(
            initialItems: [
              MaterialItem(type: WasteType.plastic),
              MaterialItem(type: WasteType.eggCarton),
            ],
          ),
          size: config.$1,
          scale: config.$2,
        );
        expect(
          tester.getSize(find.byKey(const Key('find-recipes'))).height,
          greaterThanOrEqualTo(56),
        );
        await press(tester, find.byKey(const Key('add-material')));
        tester.view.viewInsets = const FakeViewPadding(bottom: 160);
        await tester.enterText(find.byKey(const Key('material-search')), 'cam');
        await tester.pumpAndSettle();
        await press(
          tester,
          find.byKey(const ValueKey('pick-material-glass_jar')),
        );
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await app(
          tester,
          ProjectDetailScreen(
            project: catalog.singleWhere((p) => p.id == 'project_40'),
          ),
          size: config.$1,
          scale: config.$2,
        );
        await renderPhotos(tester);
        await press(tester, find.byTooltip('AI görseli'));
        expect(
          find.textContaining('Gerçek bir ürünün çekilmiş fotoğrafı değildir.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Optional real Flutter product and confirmation previews', (
    tester,
  ) async {
    if (!const bool.fromEnvironment('PHOTO_CONFIRMATION_PREVIEW')) return;
    for (final entry in [
      (
        'confirmation',
        MaterialConfirmationScreen(
          initialItems: [
            MaterialItem(
              type: WasteType.plastic,
              quantity: 2,
              name: 'PET şişe',
            ),
            MaterialItem(type: WasteType.cardboard, name: 'Karton kutu'),
            MaterialItem(type: WasteType.paperCup),
          ],
        ),
      ),
      (
        'pet-detail',
        ProjectDetailScreen(
          project: catalog.singleWhere((p) => p.id == 'project_40'),
        ),
      ),
      (
        'bowling-card',
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: ProjectCard(
                project: catalog.singleWhere((p) => p.id == 'project_15'),
              ),
            ),
          ),
        ),
      ),
    ]) {
      final key = GlobalKey();
      await app(tester, entry.$2, boundary: key);
      if (entry.$1 == 'confirmation') {
        await press(tester, find.text('Onayla').first);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, 1200),
        );
        await tester.pumpAndSettle();
      } else {
        await renderPhotos(tester);
      }
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 1.5);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final target = File(
          '.dart_tool/17-photos-confirmation/previews/${entry.$1}.png',
        );
        await target.parent.create(recursive: true);
        await target.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    }
  });
}
