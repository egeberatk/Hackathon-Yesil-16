import '../models/material_item.dart';
import '../models/upcycling_project.dart';

class MissingMaterial {
  const MissingMaterial({
    required this.materialId,
    required this.name,
    required this.quantity,
  });
  final String materialId, name;
  final int quantity;
}

class RecipeMatch {
  const RecipeMatch({required this.project, required this.missingMaterials});
  final UpcyclingProject project;
  final List<MissingMaterial> missingMaterials;
  bool get canMake => missingMaterials.isEmpty;
  int get totalMissing =>
      missingMaterials.fold(0, (sum, item) => sum + item.quantity);
}

class RecipeMatchingService {
  static List<RecipeMatch> match(
    List<UpcyclingProject> projects,
    List<MaterialItem> items,
  ) {
    final inventory = <String, int>{};
    for (final item in items) {
      final id = item.type.materialId;
      if (id == null || item.requiresConfirmation || item.quantity <= 0) {
        continue;
      }
      inventory.update(
        id,
        (count) => count + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }
    final matches = projects.map((project) {
      final requirements = <String, int>{};
      final names = <String, String>{};
      for (final material in project.requiredMaterials) {
        names[material.materialId] = material.name;
        requirements.update(
          material.materialId,
          (count) => count + material.quantity,
          ifAbsent: () => material.quantity,
        );
      }
      final missing = <MissingMaterial>[];
      for (final entry in requirements.entries) {
        final shortage = entry.value - (inventory[entry.key] ?? 0);
        if (shortage > 0) {
          missing.add(
            MissingMaterial(
              materialId: entry.key,
              name: names[entry.key]!,
              quantity: shortage,
            ),
          );
        }
      }
      return RecipeMatch(
        project: project,
        missingMaterials: List.unmodifiable(missing),
      );
    }).toList();
    matches.sort((a, b) {
      final types = a.missingMaterials.length.compareTo(
        b.missingMaterials.length,
      );
      if (types != 0) return types;
      final quantity = a.totalMissing.compareTo(b.totalMissing);
      if (quantity != 0) return quantity;
      return a.project.id.compareTo(b.project.id);
    });
    return matches;
  }
}
