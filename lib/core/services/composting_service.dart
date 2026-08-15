import 'package:earthos/core/services/gemini_service.dart';

class CompostingService {
  static const List<Map<String, dynamic>> quickTips = [
    {
      'title': 'Kitchen Scraps',
      'items': ['Vegetable peels', 'Fruit cores', 'Coffee grounds', 'Eggshells'],
      'time': '2-3 months',
      'icon': 'kitchen',
    },
    {
      'title': 'Yard Waste',
      'items': ['Grass clippings', 'Dry leaves', 'Small branches', 'Weeds (no seeds)'],
      'time': '3-6 months',
      'icon': 'yard',
    },
    {
      'title': 'Paper Products',
      'items': ['Newspaper', 'Cardboard', 'Paper towels', 'Napkins'],
      'time': '4-6 months',
      'icon': 'paper',
    },
    {
      'title': 'AVOID',
      'items': ['Meat', 'Dairy', 'Oils', 'Pet waste', 'Diseased plants'],
      'time': 'Never compost',
      'icon': 'warning',
    },
  ];

  static Future<String> getPersonalizedGuide({
    required String wasteType,
    required String location,
  }) async {
    final prompt = '''
User has $wasteType waste in $location.

Provide a 3-sentence composting guide covering:
1. Can this waste be composted? Yes/No/Partially
2. If yes, specific method (bin, pile, worm bin, etc.) suitable for their location
3. One local tip based on climate

Keep concise, actionable, no markdown.
''';
    try {
      return await GeminiService.generate(prompt);
    } catch (e) {
      return 'Consider composting organic waste to reduce landfill impact.';
    }
  }

  static bool isCompostable(String wasteType) {
    final compostable = ['organic', 'food', 'yard', 'paper'];
    return compostable.any((t) => wasteType.toLowerCase().contains(t));
  }
}
