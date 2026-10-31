import 'dart:convert';

import 'package:flutter/services.dart';

class RecipePhoto {
  const RecipePhoto({
    required this.asset,
    required this.title,
    required this.author,
    required this.sourceUrl,
    required this.license,
    required this.licenseUrl,
    this.aiGenerated = false,
  });
  final String asset, title, author, sourceUrl, license, licenseUrl;
  final bool aiGenerated;
  static RecipePhoto? parse(dynamic value) {
    if (value is! Map ||
        value['verified'] != true ||
        value['matches_recipe'] != true) {
      return null;
    }
    if (value['kind'] == 'ai_generated') {
      if (value['title'] is! String ||
          (value['title'] as String).trim().isEmpty ||
          value['generator'] != 'image_gen' ||
          value['asset'] is! String ||
          !RegExp(r'^assets/recipes/photos/project_\d+\.webp$')
              .hasMatch(value['asset'])) {
        return null;
      }
      return RecipePhoto(
        asset: value['asset'],
        title: value['title'],
        author: 'image_gen',
        sourceUrl: '',
        license: '',
        licenseUrl: '',
        aiGenerated: true,
      );
    }
    for (final key in [
      'asset',
      'title',
      'author',
      'source_url',
      'license',
      'license_url',
    ]) {
      if (value[key] is! String || (value[key] as String).trim().isEmpty) {
        return null;
      }
    }
    if (!RegExp(r'^assets/recipe_photos/[a-zA-Z0-9_-]+\.(jpg|jpeg|png|webp)$')
        .hasMatch(value['asset'])) {
      return null;
    }
    const licenses = {
      'CC0-1.0': 'https://creativecommons.org/publicdomain/zero/1.0/',
      'CC-BY-4.0': 'https://creativecommons.org/licenses/by/4.0/',
      'CC-BY-SA-4.0': 'https://creativecommons.org/licenses/by-sa/4.0/',
    };
    if (licenses[value['license']] != value['license_url'] ||
        Uri.tryParse(value['source_url'])?.scheme != 'https') {
      return null;
    }
    return RecipePhoto(
      asset: value['asset'],
      title: value['title'],
      author: value['author'],
      sourceUrl: value['source_url'],
      license: value['license'],
      licenseUrl: value['license_url'],
    );
  }
}

class RecipePhotoRepository {
  RecipePhotoRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  static const assetPath = 'assets/recipe_photos/manifest.json';
  Future<RecipePhoto?> find(String projectId) async {
    try {
      final data = jsonDecode(await _bundle.loadString(assetPath));
      if (data is! Map || data['version'] != 1 || data['photos'] is! Map) {
        return null;
      }
      final photo = RecipePhoto.parse(data['photos'][projectId]);
      if (photo?.aiGenerated == true &&
          photo!.asset != 'assets/recipes/photos/$projectId.webp') {
        return null;
      }
      return photo;
    } catch (_) {
      return null;
    }
  }
}
