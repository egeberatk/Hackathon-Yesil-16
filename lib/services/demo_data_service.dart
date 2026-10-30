import '../models/material_item.dart';

class DemoDataService {
  // Fotoğraf analizi yapılmaz. Her seçim için bağımsız Örnek liste döner.
  static List<MaterialItem> materials() => [
    MaterialItem(type: WasteType.glass, quantity: 2),
    MaterialItem(type: WasteType.plastic),
  ];
}
