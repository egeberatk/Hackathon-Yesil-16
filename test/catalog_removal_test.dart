import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_projesi/animations/workshop_steps.dart';
import 'package:hackathon_projesi/core/recipe_safety_copy.dart';
import 'package:hackathon_projesi/models/material_item.dart';
import 'package:hackathon_projesi/services/material_candidate_filter.dart';
import 'package:hackathon_projesi/services/recipe_matching_service.dart';
import 'package:hackathon_projesi/services/recipe_repository.dart';
import 'package:hackathon_projesi/widgets/recipe_project_preview.dart';

const retiredIds = {
  'project_02',
  'project_05',
  'project_06',
  'project_20',
  'project_28',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Retired recipes and alternate titles are absent from active catalogue',
    () async {
      final source = await rootBundle.loadString(RecipeRepository.assetPath);
      final data = jsonDecode(source) as Map<String, dynamic>;
      final recipes = RecipeRepository.parse(source);
      final ids = recipes.map((p) => p.id).toSet();
      expect(recipes, hasLength(17));
      expect(ids, (data['approved_ids'] as List).toSet());
      expect((data['projects'] as List).map((p) => p['id']).toSet(), ids);
      expect(ids.intersection(retiredIds), isEmpty);
      for (final p in recipes) {
        final name = MaterialCandidateFilter.folded(p.name);
        expect(
          name,
          isNot(
            matches(
              r'kablo.*duzenleyici|fotograf.*cerceve|(?:ani|sukran).*kavanoz|hedef.*vurma|kagit.*ayracli.*kutu',
            ),
          ),
        );
      }
    },
  );

  test(
    'All remaining recipes match without reviving retired projects',
    () async {
      final recipes = await RecipeRepository().load();
      final inventory = [
        for (final type in WasteType.values)
          if (type != WasteType.unknown)
            MaterialItem(type: type, quantity: 999),
      ];
      final results = RecipeMatchingService.match(recipes, inventory);
      expect(results, hasLength(17));
      expect(results.every((m) => m.canMake), isTrue);
      expect(
        results.map((m) => m.project.id).toSet().intersection(retiredIds),
        isEmpty,
      );
      expect(
        WorkshopSteps.recipes.keys.toSet().intersection(retiredIds),
        isEmpty,
      );
      expect(
        RecipeSafetyCopy.summaries.keys.toSet().intersection(retiredIds),
        isEmpty,
      );
      expect(RecipeProjectPreview.staticIds.intersection(retiredIds), isEmpty);
    },
  );

  test(
    'Removed photos and generation inputs are absent; retained photos survive',
    () {
      final folder = Directory('assets/recipes/photos');
      final manifest = jsonDecode(
        File('${folder.path}/generation_manifest.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final catalog = jsonDecode(
        File('assets/recipes/projects.json').readAsStringSync(),
      );
      final active = (catalog['approved_ids'] as List).toSet();
      expect((manifest['scope'] as List).toSet(), active);
      for (final key in ['prompts', 'images']) {
        expect((manifest[key] as Map).keys.toSet(), active);
      }
      for (final id in retiredIds) {
        expect(File('${folder.path}/$id.webp').existsSync(), isFalse);
        expect(jsonEncode(manifest), isNot(contains(id)));
      }
      expect(
        folder
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.webp'))
            .map((f) => f.uri.pathSegments.last)
            .toSet(),
        active.map((id) => '$id.webp').toSet(),
      );
      final activePhotos = jsonDecode(
        File('assets/recipe_photos/manifest.json').readAsStringSync(),
      );
      expect(
        (activePhotos['photos'] as Map).keys.toSet().intersection(retiredIds),
        isEmpty,
      );
    },
  );
}
