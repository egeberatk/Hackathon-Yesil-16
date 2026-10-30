import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_projesi/main.dart';
import 'package:hackathon_projesi/screens/material_confirmation_screen.dart';
import 'package:hackathon_projesi/models/material_item.dart';
import 'package:hackathon_projesi/services/demo_data_service.dart';

void main() {
  testWidgets('Ana sayfa fotoğraf seçeneklerini gösterir', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(const ReBornApp());
    await tester.pumpAndSettle();
    expect(find.text('ReBorn AI'), findsOneWidget);
    expect(find.text('Fotoğraf çek'), findsOneWidget);
    expect(find.text('Galeriden seç'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });
  testWidgets('Malzeme düzenleme, ekleme, silme ve proje akışı', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MaterialConfirmationScreen()),
    );
    await tester.tap(find.byTooltip('Malzemeyi düzenle').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('material-quantity')), '0');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('1 ile 999 arasında tam sayı gir.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('material-quantity')), '3');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('3 adet'), findsOneWidget);
    await tester.tap(find.text('Malzeme ekle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Malzemeyi sil'), findsNWidgets(3));
    await tester.tap(find.byTooltip('Malzemeyi sil').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Malzemeyi sil'), findsNWidgets(2));
    await tester.ensureVisible(find.text('Onayla ve projeleri gör'));
    await tester.tap(find.text('Onayla ve projeleri gör'));
    await tester.pumpAndSettle();
    expect(find.text('Dönüşüm fikirleri'), findsOneWidget);
    await tester.ensureVisible(find.text('Kavanozdan mini bahçe'));
    await tester.tap(find.text('Kavanozdan mini bahçe'));
    await tester.pumpAndSettle();
    expect(find.text('Gereken malzemeler'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('Aynı türdeki malzemelerin adetleri birlikte hesaplanır', () {
    final project = DemoDataService.projects[2];
    expect(
      DemoDataService.canMake(project, [
        MaterialItem(type: WasteType.cardboard),
      ]),
      isFalse,
    );
    expect(
      DemoDataService.canMake(project, [
        MaterialItem(type: WasteType.cardboard),
        MaterialItem(type: WasteType.cardboard),
      ]),
      isTrue,
    );
  });
}
