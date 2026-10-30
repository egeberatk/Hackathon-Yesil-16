import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/upcycling_project.dart';

class RecipeRepository {
  RecipeRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  static const assetPath = 'assets/recipes/projects.json';

  Future<List<UpcyclingProject>> load() async =>
      parse(await _bundle.loadString(assetPath));

  static List<UpcyclingProject> parse(String source) {
    final json = jsonDecode(source);
    if (json is! Map<String, dynamic> ||
        json['approved_ids'] is! List ||
        json['projects'] is! List) {
      throw const FormatException('Tarif kütüphanesi biçimi geçersiz.');
    }
    final approved = json['approved_ids'] as List;
    if (approved.any((id) => id is! String || id.trim().isEmpty) ||
        approved.toSet().length != approved.length) {
      throw const FormatException('Onaylı tarif kimlikleri geçersiz.');
    }
    final ids = <String>{};
    final projects = <UpcyclingProject>[];
    for (final record in json['projects'] as List) {
      if (record is! Map<String, dynamic> || record['id'] is! String) {
        throw const FormatException('Tarif kaydı veya kimliği geçersiz.');
      }
      // Kaynak katalog büyüse de yalnızca açıkça onaylanmış tarifler yüklenir.
      if (!approved.contains(record['id'])) continue;
      final project = UpcyclingProject.fromJson(record);
      if (!ids.add(project.id)) {
        throw const FormatException('Tekrarlanan tarif kimliği.');
      }
      projects.add(project);
    }
    return List.unmodifiable(projects);
  }
}
