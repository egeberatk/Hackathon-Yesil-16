class RequiredMaterial {
  const RequiredMaterial({
    required this.materialId,
    required this.name,
    required this.quantity,
  });
  final String materialId, name;
  final int quantity;

  factory RequiredMaterial.fromJson(Map<String, dynamic> json) =>
      RequiredMaterial(
        materialId: _text(json, 'material_id'),
        name: _text(json, 'name'),
        quantity: _positiveInt(json, 'quantity'),
      );
}

class UpcyclingProject {
  const UpcyclingProject({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredMaterials,
    required this.requiredSupplies,
    required this.optionalSupplies,
    required this.category,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.steps,
    required this.practicalUse,
    required this.safetyWarning,
    required this.imagePrompt,
  });
  final String id,
      name,
      description,
      category,
      difficulty,
      practicalUse,
      safetyWarning,
      imagePrompt;
  final int estimatedMinutes;
  final List<RequiredMaterial> requiredMaterials;
  final List<String> requiredSupplies, optionalSupplies, steps;

  factory UpcyclingProject.fromJson(Map<String, dynamic> json) {
    final materials = json['required_materials'];
    if (materials is! List || materials.isEmpty) {
      throw const FormatException('required_materials dolu bir liste olmalı.');
    }
    final steps = _texts(json, 'steps');
    if (steps.isEmpty) throw const FormatException('steps boş olamaz.');
    return UpcyclingProject(
      id: _text(json, 'id'),
      name: _text(json, 'name'),
      description: _text(json, 'description'),
      requiredMaterials: List.unmodifiable(
        materials.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Geçersiz gerekli malzeme.');
          }
          return RequiredMaterial.fromJson(item);
        }),
      ),
      requiredSupplies: _texts(json, 'required_supplies'),
      optionalSupplies: _texts(json, 'optional_supplies'),
      category: _text(json, 'category'),
      difficulty: _text(json, 'difficulty'),
      estimatedMinutes: _positiveInt(json, 'estimated_minutes'),
      steps: steps,
      practicalUse: _text(json, 'practical_use'),
      safetyWarning: _text(json, 'safety_warning', allowEmpty: true),
      imagePrompt: _text(json, 'image_prompt', allowEmpty: true),
    );
  }
}

String _text(Map<String, dynamic> json, String key, {bool allowEmpty = false}) {
  final value = json[key];
  if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
    throw FormatException('$key geçerli bir metin olmalı.');
  }
  return value.trim();
}

int _positiveInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int || value <= 0) {
    throw FormatException('$key pozitif tam sayı olmalı.');
  }
  return value;
}

List<String> _texts(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List ||
      value.any((item) => item is! String || item.trim().isEmpty)) {
    throw FormatException('$key metin listesi olmalı.');
  }
  return List<String>.unmodifiable(
    value.map((item) => (item as String).trim()),
  );
}
