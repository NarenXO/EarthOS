import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:earthos/core/services/forest_service.dart';
import 'package:earthos/features/report/services/report_service.dart';

class SystemContextService {
  final ReportService _reportService = ReportService();
  final ForestService _forestService = ForestService();

  // Haversine formula to calculate distance between two coordinates in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  Future<Map<String, dynamic>> fetchSystemContext(String userId) async {
    try {
      // Get user location
      Position? currentPosition;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.deniedForever) {
          currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
        }
      } catch (e) {
        // Location not available, continue without it
      }

      // Fetch user impact
      final userImpact = await _reportService.fetchUserImpact(userId);

      // Fetch global impact
      final globalImpact = await _reportService.fetchImpactStats();

      // Fetch leaderboard and compute rank
      final leaderboard = await _reportService.fetchLeaderboard();
      int userRank = leaderboard.length + 1; // Default to last if not found
      for (int i = 0; i < leaderboard.length; i++) {
        if (leaderboard[i]['userId'] == userId) {
          userRank = i + 1;
          break;
        }
      }

      // Fetch forest alerts
      Map<String, dynamic> forestAlerts = {};
      if (currentPosition != null) {
        forestAlerts = await _forestService.fetchForestAlerts(
          lat: currentPosition.latitude,
          lng: currentPosition.longitude,
        );
      } else {
        forestAlerts = {
          'alertCount': 0,
          'highConfidence': 0,
          'mediumConfidence': 0,
          'recentAlerts': 0,
        };
      }

      // Count nearby open reports (within 1km)
      int nearbyOpenReports = 0;
      if (currentPosition != null) {
        final allReports = await _reportService.fetchReports();
        for (final report in allReports) {
          if (report.status != 'verified') {
            final distance = _calculateDistance(
              currentPosition.latitude,
              currentPosition.longitude,
              report.lat,
              report.lng,
            );
            if (distance <= 1.0) {
              nearbyOpenReports++;
            }
          }
        }
      }

      return {
        'userImpact': userImpact,
        'globalImpact': globalImpact,
        'rank': userRank,
        'nearbyOpenReports': nearbyOpenReports,
        'forestAlerts': forestAlerts,
      };
    } catch (e) {
      return {
        'userImpact': {},
        'globalImpact': {},
        'rank': 0,
        'nearbyOpenReports': 0,
        'forestAlerts': {
          'alertCount': 0,
          'highConfidence': 0,
          'mediumConfidence': 0,
          'recentAlerts': 0,
        },
      };
    }
  }
}
