import 'package:earthos/core/services/species_impact_service.dart';
import 'package:earthos/core/services/gemini_service.dart';

class WildlifeAlertService {
  static const Map<String, int> _highRiskWasteTypes = {
    'plastic': 3,
    'e-waste': 5,
    'metal': 2,
    'mixed': 3,
    'organic': 1,
    'unknown': 2,
  };

  static Future<Map<String, dynamic>> assessWildlifeRisk({
    required double lat,
    required double lng,
    required String wasteType,
    required int severity,
  }) async {
    try {
      final speciesData = await SpeciesImpactService.fetchNearbySpecies(lat, lng);
      final speciesCount = speciesData['count'] ?? 0;
      final wasteRisk = _highRiskWasteTypes[wasteType.toLowerCase()] ?? 2;
      
      final riskScore = (speciesCount * wasteRisk * severity).clamp(0, 100);
      
      String level;
      String action;
      if (riskScore >= 50) {
        level = 'CRITICAL';
        action = 'Immediate cleanup required. Contact wildlife authorities.';
      } else if (riskScore >= 25) {
        level = 'HIGH';
        action = 'Schedule cleanup within 48 hours.';
      } else if (riskScore >= 10) {
        level = 'MODERATE';
        action = 'Plan cleanup this week.';
      } else {
        level = 'LOW';
        action = 'Standard cleanup priority.';
      }
      
      String? aiAdvice;
      if (riskScore >= 25 && speciesData['species'] != null) {
        final speciesList = (speciesData['species'] as List)
            .take(3)
            .map((s) => s['name'])
            .join(', ');
        final prompt = '''
Waste type "$wasteType" (severity $severity/5) is near these threatened species: $speciesList.
In 2 sentences, explain the specific danger to these species and recommended immediate action.
No markdown.
''';
        try {
          aiAdvice = await GeminiService.generate(prompt);
        } catch (_) {
          aiAdvice = null;
        }
      }
      
      return {
        'riskScore': riskScore,
        'level': level,
        'action': action,
        'speciesAtRisk': speciesCount,
        'aiAdvice': aiAdvice,
      };
    } catch (e) {
      print('Wildlife risk error: $e');
      return {'riskScore': 0, 'level': 'UNKNOWN', 'action': 'Unable to assess'};
    }
  }
}
