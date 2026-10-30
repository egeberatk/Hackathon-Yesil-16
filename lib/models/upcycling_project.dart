import 'material_item.dart';

class UpcyclingProject {
  const UpcyclingProject({
    required this.title,
    required this.description,
    required this.symbol,
    required this.minutes,
    required this.requirements,
    required this.extras,
    required this.steps,
  });
  final String title, description, symbol;
  final int minutes;
  final Map<WasteType, int> requirements;
  final List<String> extras, steps;
}
