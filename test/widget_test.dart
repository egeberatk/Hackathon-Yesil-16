import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_projesi/main.dart';
import 'package:hackathon_projesi/screens/material_confirmation_screen.dart';

class TestRecipeBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture('{"approved_ids":[],"projects":[]}');
  @override
  Future<ByteData> load(String key) => throw UnsupportedError(key);
}

void main() {
  testWidgets('Ana sayfa fotoğraf seçeneklerini gösterir', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(
      DefaultAssetBundle(bundle: TestRecipeBundle(), child: const ReBornApp()),
    );
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;
    expect(find.text('Atıktan Artıya'), findsOneWidget);
    expect(find.text('Atığını Tara'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Galeriden seç'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Malzeme düzenleme, ekleme, silme ve proje akışı', (
    tester,
  ) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestRecipeBundle(),
        child: const MaterialApp(home: MaterialConfirmationScreen()),
      ),
    );
    await tester.ensureVisible(find.byTooltip('Malzemeyi düzenle').first);
    await tester.tap(find.byTooltip('Malzemeyi düzenle').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('material-quantity')), '0');
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('1 ile 999 arasında tam sayı gir.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('material-quantity')), '3');
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('3 adet'), findsOneWidget);
    await tester.ensureVisible(find.text('Malzeme Ekle'));
    await tester.tap(find.text('Malzeme Ekle'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('pick-material-cardboard_box')),
    );
    await tester.tap(find.byKey(const ValueKey('pick-material-cardboard_box')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Malzemeyi sil'), findsNWidgets(3));
    await tester.ensureVisible(find.byTooltip('Malzemeyi sil').last);
    await tester.tap(find.byTooltip('Malzemeyi sil').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Malzemeyi sil'), findsNWidgets(2));
    await tester.ensureVisible(find.text('Projeleri Keşfet'));
    await tester.tap(find.text('Projeleri Keşfet'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Dönüşüm fikirleri'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
