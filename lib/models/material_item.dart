enum WasteType {
  glass('Cam kavanoz', 'glass_jar'),
  plastic('Plastik şişe', 'pet_bottle'),
  cardboard('Karton kutu', 'cardboard_box'),
  metal('Metal kutu', 'metal_can'),
  plasticCap('Plastik kapak', 'plastic_cap'),
  cardboardRoll('Karton rulo', 'cardboard_roll'),
  cleanPaper('Temiz kağıt', 'clean_paper'),
  plasticPackaging('Plastik ambalaj', 'plastic_packaging'),
  yogurtContainer('Yoğurt kabı', 'yogurt_container'),
  eggCarton('Yumurta kolisi', 'egg_carton'),
  unknown('Bilinmeyen / onay gerekli', null);

  const WasteType(this.label, this.materialId);
  final String label;
  final String? materialId;

  static WasteType fromId(String? id) =>
      values.firstWhere((type) => type.materialId == id, orElse: () => unknown);
}

class MaterialItem {
  MaterialItem({
    required this.type,
    this.quantity = 1,
    String? name,
    this.confidence = 'certain',
    this.requiresConfirmation = false,
  }) : name = name ?? type.label;
  WasteType type;
  int quantity;
  String name;
  String confidence;
  bool requiresConfirmation;

  MaterialItem copy() => MaterialItem(
    type: type,
    quantity: quantity,
    name: name,
    confidence: confidence,
    requiresConfirmation: requiresConfirmation,
  );

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final id = json['material_id'];
    final quantity = json['quantity'];
    final confidence = json['confidence'];
    final confirmation = json['requires_confirmation'];
    if (name is! String ||
        name.trim().isEmpty ||
        name.length > 120 ||
        (id != null && id is! String) ||
        quantity is! int ||
        quantity < 1 ||
        quantity > 999 ||
        !['certain', 'uncertain'].contains(confidence) ||
        confirmation is! bool) {
      throw const FormatException('Geçersiz malzeme verisi.');
    }
    final type = WasteType.fromId(id as String?);
    return MaterialItem(
      type: type,
      name: name.trim(),
      quantity: quantity,
      confidence: type == WasteType.unknown
          ? 'uncertain'
          : confidence as String,
      requiresConfirmation:
          confirmation ||
          type == WasteType.unknown ||
          confidence == 'uncertain',
    );
  }
}
