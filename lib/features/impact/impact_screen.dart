/*
|--------------------------------------------------------------------------
| EarthOS
| File: impact_screen.dart
| Feature: Impact Module
| Author: Naren
|--------------------------------------------------------------------------
| Global + Personal Environmental Impact Dashboard
|--------------------------------------------------------------------------
*/

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:earthos/core/constants/app_colors.dart';
import 'package:earthos/core/services/forest_service.dart';
import 'package:earthos/core/services/risk_engine.dart';
import 'package:earthos/core/services/trend_service.dart';
import 'package:earthos/core/services/recommendation_engine.dart';
import 'package:earthos/core/services/air_quality_service.dart';
import 'package:earthos/core/services/weather_service.dart';
import 'package:earthos/features/report/services/report_service.dart';
import 'package:earthos/features/axis/services/system_context_service.dart';
import 'package:earthos/core/services/user_identity_service.dart';

class ImpactScreen extends StatefulWidget {
  const ImpactScreen({super.key});

  @override
  State<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends State<ImpactScreen> {
  final ReportService _reportService = ReportService();
  final ForestService _forestService = ForestService();
  final SystemContextService _systemContextService = SystemContextService();
  final UserIdentityService _userIdentityService = UserIdentityService();
  final TrendService _trendService = TrendService();
  
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _forestAlerts;
  Map<String, dynamic>? _systemContext;
  Map<String, dynamic>? _trends;
  Map<String, dynamic>? _airQuality;
  Map<String, dynamic>? _weather;
  List<String>? _recommendations;
  double? _riskScore;
  bool _isLoading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _initializeLocation();
    _fetchForestAlerts();
    _fetchSystemContext();
    _fetchTrends();
    _fetchAirQuality();
    _fetchWeather();
  }

  Future<void> _fetchTrends() async {
    try {
      final reports = await _reportService.fetchReports();
      final reportsJson = reports.map((r) => r.toJson()).toList();
      
      // Mock forest alerts data for trend calculation
      final forestAlertsJson = <Map<String, dynamic>>[];
      
      final trends = await _trendService.calculateTrends(
        reports: reportsJson,
        forestAlerts: forestAlertsJson,
      );

      setState(() {
        _trends = trends;
      });
    } catch (e) {
      // Silently fail, keep default values
    }
  }

  Future<void> _fetchSystemContext() async {
    try {
      final user = await _userIdentityService.getOrCreateUser();
      final context = await _systemContextService.fetchSystemContext(user.id);
      
      final nearbyOpenReports = context['nearbyOpenReports'] as int? ?? 0;
      final forestAlerts = context['forestAlerts'] as Map<String, dynamic>? ?? {};
      final highForestAlerts = forestAlerts['highConfidence'] as int? ?? 0;
      
      // Count sensitive reports from global stats
      final sensitiveReports = _stats?['totalSensitiveReports'] as int? ?? 0;
      
      // Calculate days since last cleanup (default to 30 if no recent activity)
      final daysSinceLastCleanup = 30; // Simplified for now
      
      final score = RiskEngine.calculateRiskScore(
        nearbyOpenReports: nearbyOpenReports,
        sensitiveReports: sensitiveReports,
        highForestAlerts: highForestAlerts,
        daysSinceLastCleanup: daysSinceLastCleanup,
      );

      // Generate recommendations
      final rank = context['rank'] as int? ?? 0;
      final recommendations = RecommendationEngine.generateRecommendations(
        riskScore: score,
        trends: _trends ?? {},
        nearbyOpenReports: nearbyOpenReports,
        forestHighConfidence: highForestAlerts,
        userRank: rank,
      );

      setState(() {
        _systemContext = context;
        _riskScore = score;
        _recommendations = recommendations;
      });
    } catch (e) {
      // Silently fail, keep default values
    }
  }

  Future<void> _initializeLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await _reportService.fetchImpactStats();
      final totalReports = stats['totalReports'] ?? 0;
      final verified = stats['verifiedReports'] ?? 0;
      final carbon = (stats['totalCarbonImpact'] as num?)?.toDouble() ?? 0.0;

      print('Impact fetch: totalReports=$totalReports, verified=$verified, carbon=$carbon');
      print('Impact UI stats: $stats');

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Impact fetch error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchForestAlerts() async {
    if (_currentPosition == null) await _initializeLocation();
    if (_currentPosition == null) return;

    try {
      final alerts = await _forestService.fetchForestAlerts(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
      );
      setState(() {
        _forestAlerts = alerts;
      });
    } catch (e) {
      // Silently fail, keep empty data
    }
  }

  Future<void> _fetchAirQuality() async {
    if (_currentPosition == null) return;

    try {
      final aqi = await AirQualityService.fetchAQI(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      setState(() {
        _airQuality = aqi;
      });
    } catch (e) {
      // Silently fail, keep empty data
    }
  }

  Future<void> _fetchWeather() async {
    if (_currentPosition == null) return;

    try {
      final weather = await WeatherService.fetchWeather(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      setState(() {
        _weather = weather;
      });
    } catch (e) {
      // Silently fail, keep empty data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Impact"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ===============================
            // AIR QUALITY CARD
            // ===============================
            _buildAirQualityCard(),

            const SizedBox(height: 20),

            // ===============================
            // WEATHER + CLEANUP CARD
            // ===============================
            _buildWeatherCard(),

            const SizedBox(height: 30),

            // ===============================
            // GLOBAL IMPACT SECTION
            // ===============================
            Text(
              "Global Impact",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildImpactGrid(),

            const SizedBox(height: 30),

            // ===============================
            // ENVIRONMENTAL RISK INDEX
            // ===============================
            Text(
              "Environmental Risk Index",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildRiskIndexCard(),

            const SizedBox(height: 30),

            // ===============================
            // ENVIRONMENTAL TRENDS
            // ===============================
            Text(
              "📊 Environmental Trends",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildTrendsCard(),

            const SizedBox(height: 30),

            // ===============================
            // RECOMMENDED ACTIONS
            // ===============================
            Text(
              "✅ Recommended Actions",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildRecommendationsCard(),

            const SizedBox(height: 30),

            // ===============================
            // AIR QUALITY SECTION
            // ===============================
            Text(
              "Local Air Quality",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildAQICard(),

            const SizedBox(height: 30),

            // ===============================
            // PROJECTION SECTION
            // ===============================
            Text(
              "Emission Projection",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildProjectionCard(),

            const SizedBox(height: 30),

            // ===============================
            // PERSONAL ENVIRONMENT DATA
            // ===============================
            Text(
              "Personal Environmental Context",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildPersonalEnvironmentCard(),

            const SizedBox(height: 30),

            // ===============================
            // FOREST LOSS MONITOR
            // ===============================
            Text(
              "🌲 Forest Loss Monitor",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildForestAlertsCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // AIR QUALITY CARD
  // =========================================================
  Widget _buildAirQualityCard() {
    if (_airQuality == null) {
      return const SizedBox.shrink();
    }

    final aqi = _airQuality!['aqi'] as int? ?? 0;
    final category = _airQuality!['category'] as String? ?? 'Unknown';
    final city = _airQuality!['city'] as String? ?? 'Unknown';
    final color = _airQuality!['color'] as int? ?? 0xFF888888;
    final advice = _airQuality!['healthAdvice'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(color).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(color), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.air, size: 24),
              const SizedBox(width: 8),
              Text(
                'Air Quality',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '$aqi',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(color),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(color),
                      ),
                    ),
                    Text(
                      city,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            advice,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // WEATHER + CLEANUP CARD
  // =========================================================
  Widget _buildWeatherCard() {
    if (_weather == null) {
      return const SizedBox.shrink();
    }

    final temp = _weather!['temp'] as double? ?? 0.0;
    final condition = _weather!['condition'] as String? ?? 'Unknown';
    final description = _weather!['description'] as String? ?? '';
    final humidity = _weather!['humidity'] as int? ?? 0;
    final windSpeed = _weather!['windSpeed'] as double? ?? 0.0;
    final recommendation = _weather!['cleanupRecommendation'] as String? ?? '';
    final suitable = _weather!['suitable'] as bool? ?? false;

    IconData weatherIcon;
    if (condition.toLowerCase().contains('rain')) {
      weatherIcon = Icons.water_drop;
    } else if (condition.toLowerCase().contains('cloud')) {
      weatherIcon = Icons.cloud;
    } else if (condition.toLowerCase().contains('clear')) {
      weatherIcon = Icons.wb_sunny;
    } else {
      weatherIcon = Icons.cloud_circle;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(weatherIcon, size: 24),
              const SizedBox(width: 8),
              Text(
                'Weather + Cleanup',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${temp.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Humidity: $humidity% | Wind: ${windSpeed.toStringAsFixed(1)} m/s',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: suitable 
                  ? const Color(0xFF00C896).withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: suitable ? const Color(0xFF00C896) : Colors.orange,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  suitable ? Icons.check_circle : Icons.info,
                  color: suitable ? const Color(0xFF00C896) : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // GLOBAL IMPACT GRID
  // =========================================================
  Widget _buildImpactGrid() {
    final totalReports = _stats?['totalReports'] ?? 0;
    final verifiedReports = _stats?['verifiedReports'] ?? 0;
    final totalCarbonImpact = _stats?['totalCarbonImpact'] ?? 0.0;
    final totalSensitiveReports = _stats?['totalSensitiveReports'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _ImpactCard(title: "Total Reports", value: totalReports.toString()),
        _ImpactCard(
          title: "Verified Cleanups",
          value: verifiedReports.toString(),
        ),
        _ImpactCard(
          title: "Total CO₂ Impact (kg)",
          value: totalCarbonImpact.toStringAsFixed(1),
        ),
        _ImpactCard(
          title: "Sensitive Zone Incidents",
          value: totalSensitiveReports.toString(),
        ),
      ],
    );
  }

  // =========================================================
  // AQI CARD
  // =========================================================
  Widget _buildAQICard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "AQI: 74 (Moderate)",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "PM2.5: 28 µg/m³\nTemperature: 31°C\nHumidity: 62%",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PROJECTION CARD
  // =========================================================
  Widget _buildProjectionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "If unresolved for 12 months:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Projected Emissions: 3.1T CO₂e\nEquivalent to 680 cars/year",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PERSONAL ENVIRONMENT CARD
  // =========================================================
  Widget _buildPersonalEnvironmentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Area Risk Index: Moderate",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "4 unresolved sites within 1 km\n1 hospital zone nearby\n2 wildlife-sensitive areas",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FOREST ALERTS CARD
  // =========================================================
  Widget _buildForestAlertsCard() {
    final alertCount = _forestAlerts?['alertCount'] ?? 0;
    final highConfidence = _forestAlerts?['highConfidence'] ?? 0;
    final mediumConfidence = _forestAlerts?['mediumConfidence'] ?? 0;
    final recentAlerts = _forestAlerts?['recentAlerts'] ?? 0;

    // Determine if warning color should be shown
    final isWarning = highConfidence > 5 || recentAlerts > 10;
    final trendColor = isWarning ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Forest Loss Alerts Nearby",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: trendColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      isWarning ? Icons.warning : Icons.check_circle,
                      size: 16,
                      color: trendColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isWarning ? 'Warning' : 'Normal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ForestMetric(
                  label: "Total Alerts",
                  value: alertCount.toString(),
                ),
              ),
              Expanded(
                child: _ForestMetric(
                  label: "High Confidence",
                  value: highConfidence.toString(),
                  isWarning: highConfidence > 5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ForestMetric(
                  label: "Medium Confidence",
                  value: mediumConfidence.toString(),
                ),
              ),
              Expanded(
                child: _ForestMetric(
                  label: "Recent (30 days)",
                  value: recentAlerts.toString(),
                  isWarning: recentAlerts > 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // RISK INDEX CARD
  // =========================================================
  Widget _buildRiskIndexCard() {
    final score = _riskScore ?? 0.0;
    final status = RiskEngine.getRiskStatus(score);
    
    Color statusColor;
    if (status == 'Low') {
      statusColor = Colors.green;
    } else if (status == 'Moderate') {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Environmental Risk Index",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  score.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
                const Text(
                  '/ 100',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getRiskDescription(status),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getRiskDescription(String status) {
    switch (status) {
      case 'Low':
        return 'Environmental conditions in your area are stable. Continue monitoring.';
      case 'Moderate':
        return 'Some environmental risks detected. Consider addressing nearby cleanup reports.';
      case 'High':
        return 'Significant environmental risks present. Immediate action recommended.';
      default:
        return 'Unable to determine risk status.';
    }
  }

  // =========================================================
  // TRENDS CARD
  // =========================================================
  Widget _buildTrendsCard() {
    final weeklyReportChange = _trends?['weeklyReportChange'] as double? ?? 0.0;
    final cleanupEfficiencyChange = _trends?['cleanupEfficiencyChange'] as double? ?? 0.0;
    final forestTrendChange = _trends?['forestTrendChange'] as double? ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TrendItem(
            label: 'Waste Reporting Trend',
            change: weeklyReportChange,
            isGood: weeklyReportChange < 0,
          ),
          const SizedBox(height: 12),
          _TrendItem(
            label: 'Cleanup Efficiency Trend',
            change: cleanupEfficiencyChange,
            isGood: cleanupEfficiencyChange > 0,
          ),
          const SizedBox(height: 12),
          _TrendItem(
            label: 'Forest Alert Trend',
            change: forestTrendChange,
            isGood: forestTrendChange < 0,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // RECOMMENDATIONS CARD
  // =========================================================
  Widget _buildRecommendationsCard() {
    final recommendations = _recommendations ?? [];
    final topRecommendations = recommendations.take(2).toList();

    if (topRecommendations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: const Text(
          'No specific recommendations at this time.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: topRecommendations.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    );
  }
}

// =============================================================
// IMPACT CARD WIDGET
// =============================================================
class _ImpactCard extends StatelessWidget {
  final String title;
  final String value;

  const _ImpactCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// TREND ITEM WIDGET
// =============================================================
class _TrendItem extends StatelessWidget {
  final String label;
  final double change;
  final bool isGood;

  const _TrendItem({
    required this.label,
    required this.change,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGood ? Colors.green : Colors.red;
    final icon = change >= 0 ? Icons.trending_up : Icons.trending_down;
    
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// =============================================================
// FOREST METRIC WIDGET
// =============================================================
class _ForestMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool isWarning;

  const _ForestMetric({
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWarning 
            ? Colors.red.withOpacity(0.1)
            : AppColors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning ? Colors.red : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isWarning ? Colors.red : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}