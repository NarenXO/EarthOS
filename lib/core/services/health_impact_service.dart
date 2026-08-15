import 'gemini_service.dart';

class HealthImpactService {
  static Future<String> getHealthImpact({
    required String wasteType,
    required int severity,
    required int daysOld,
  }) async {
    final prompt = '''
A waste dump exists with these details:
- Type: $wasteType
- Severity: $severity out of 5
- Days old: $daysOld

Provide a brief health impact warning in 2-3 sentences covering:
1. Specific health risks (disease, injury, respiratory issues)
2. Vulnerable groups affected (children, elderly, workers)
3. Urgency level

Keep it concise and actionable. No markdown formatting.
''';
    return await GeminiService.generate(prompt);
  }
}
