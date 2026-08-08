class CarbonEngine {
  static final Map<String, double> _factors = {
    'plastic': 6.0,
    'metal': 4.0,
    'organic': 2.0,
    'e-waste': 8.0,
    'mixed': 5.0,
    'unknown': 3.0,
  };

  static double calculateImpact({
    required String wasteType,
    required int severity,
  }) {
    final factor = _factors[wasteType] ?? _factors['unknown']!;
    return factor * severity;
  }
}
