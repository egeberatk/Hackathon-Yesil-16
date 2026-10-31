import '../models/material_item.dart';
import '../models/upcycling_project.dart';

class CandidateSelection {
  const CandidateSelection(this.candidates, this.excluded);
  final List<MaterialItem> candidates;

  /// Original detections and a reason, retained separately from recommendations.
  final List<({MaterialItem item, String reason})> excluded;
  String? get explanation => excluded.isEmpty && candidates.isNotEmpty
      ? null
      : candidates.isEmpty
      ? 'Fotoğraftaki nesneler için bu katalogda uygun geri dönüşüm malzemesi bulunamadı. Başka bir fotoğraf seçebilir veya malzemeni manuel ekleyebilirsin.'
      : '${excluded.length} nesne, elektronik eşya olduğu veya katalogda uygun malzeme karşılığı bulunmadığı için önerilere alınmadı.';
}

/// Selection is deliberately separate from AnalysisService and recipe matching.
abstract final class MaterialCandidateFilter {
  static String folded(String name) => name
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ç', 'c')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('â', 'a')
      .replaceAll('\u0307', '');
  static bool isElectronic(String name) {
    final value = folded(name);
    if (RegExp(r'\bkarton\b.*\bkutu\w*\s*$|\b(?:telefon|bilgisayar) kutusu\s*$')
        .hasMatch(value)) {
      return false;
    }
    return RegExp(
      r'\b(kulaklik\w*|telefon\w*|bilgisayar\w*|laptop\w*|tablet\w*|headphones?\w*|earbuds?\w*|smartphones?\w*|computers?\w*|sarj aleti|powerbank|televizyon\w*|kumanda\w*|klavye\w*|mouse)\b',
    ).hasMatch(value);
  }

  static bool isPaperCup(String name) {
    final value = folded(name);
    if (isNonpaperCup(name) ||
        RegExp(r'\b(kilif\w*|rulo\w*)\b').hasMatch(value)) {
      return false;
    }
    return RegExp(
      r'\b(kagit|karton)\s+(?:kahve\s+|icecek\s+)?barda[kg]\w*\b|\bpaper\s+(?:coffee\s+)?cups?\b',
    ).hasMatch(value);
  }

  static bool isNonpaperCup(String name) => RegExp(
    r'\b(plastik|cam)\s+(?:kahve\s+|icecek\s+)?barda[kg]\w*\b|\b(plastic|glass)\s+(?:coffee\s+)?cups?\b',
  ).hasMatch(folded(name));

  static CandidateSelection select(
    List<MaterialItem> detections,
    List<UpcyclingProject> recipes,
  ) {
    final supported = {
      for (final p in recipes)
        for (final m in p.requiredMaterials) m.materialId,
    };
    final result = <MaterialItem>[],
        excluded = <({MaterialItem item, String reason})>[];
    for (final original in detections) {
      if (isElectronic(original.name)) {
        excluded.add((item: original, reason: 'electronic'));
        continue;
      }
      final item = original.copy();
      if (isNonpaperCup(item.name)) {
        excluded.add((item: original, reason: 'unsupported_cup_type'));
        continue;
      }
      if (isPaperCup(item.name) && item.type != WasteType.paperCup) {
        item.type = WasteType.paperCup;
        item.requiresConfirmation = true;
        item.confidence = 'uncertain';
      }
      if (item.type == WasteType.paperCup &&
          RegExp(r'\b(rulo\w*|kilif\w*)\b').hasMatch(folded(item.name))) {
        excluded.add((item: original, reason: 'conflicting_cup_type'));
        continue;
      }
      if (item.type == WasteType.unknown ||
          !supported.contains(item.type.materialId)) {
        excluded.add((item: original, reason: 'no_catalog_material'));
        continue;
      }
      result.add(item);
    }
    return CandidateSelection(
      List.unmodifiable(result),
      List.unmodifiable(excluded),
    );
  }
}
