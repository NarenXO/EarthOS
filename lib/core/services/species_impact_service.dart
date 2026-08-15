import 'dart:convert';
import 'package:http/http.dart' as http;

class SpeciesImpactService {
  static Future<Map<String, dynamic>> fetchNearbySpecies(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://api.inaturalist.org/v1/observations?lat=$lat&lng=$lng&radius=5&per_page=20&threatened=true',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      
      print('Species status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        final species = <Map<String, dynamic>>[];
        final seenNames = <String>{};
        
        for (var obs in results) {
          final taxon = obs['taxon'];
          if (taxon == null) continue;
          final name = taxon['preferred_common_name'] ?? taxon['name'] ?? 'Unknown';
          if (seenNames.contains(name)) continue;
          seenNames.add(name);
          
          species.add({
            'name': name,
            'scientificName': taxon['name'] ?? '',
            'iconicTaxon': taxon['iconic_taxon_name'] ?? 'Animal',
            'conservationStatus': taxon['conservation_status']?['status_name'] ?? 'Unknown',
          });
        }
        
        return {
          'count': species.length,
          'species': species.take(8).toList(),
          'atRisk': species.length,
        };
      }
      return {'count': 0, 'species': [], 'atRisk': 0};
    } catch (e) {
      print('Species error: $e');
      return {'count': 0, 'species': [], 'atRisk': 0};
    }
  }
}
