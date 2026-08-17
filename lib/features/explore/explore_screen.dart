/*
|--------------------------------------------------------------------------
| EarthOS
| File: explore_screen.dart
| Feature: Explore Module
|--------------------------------------------------------------------------
*/

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:earthos/core/constants/app_colors.dart';
import 'package:earthos/core/services/forest_service.dart';
import 'package:earthos/core/services/cleanup_verification_service.dart';
import 'package:earthos/core/services/health_impact_service.dart';
import 'package:earthos/core/services/water_body_service.dart';
import 'package:earthos/core/services/species_impact_service.dart';
import 'package:earthos/core/services/wildlife_alert_service.dart';
import 'package:earthos/core/services/composting_service.dart';
import 'package:earthos/core/services/recycling_route_service.dart';
import 'package:earthos/features/report/services/report_service.dart';
import 'package:earthos/features/report/models/report_model.dart';
import 'package:earthos/features/achievements/achievement_service.dart';
import 'package:earthos/features/achievements/achievement_popup.dart';
import 'package:earthos/features/emergency/emergency_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  String _locationText = "Fetching location...";

  final ReportService _reportService = ReportService();
  final ForestService _forestService = ForestService();
  final EmergencyService _emergencyService = EmergencyService();
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  StreamSubscription<List<Report>>? _reportsSubscription;
  final Map<String, String> _healthImpactCache = {};
  final Map<String, Map<String, dynamic>> _waterBodyCache = {};
  final Map<String, Map<String, dynamic>> _speciesCache = {};
  final Map<String, Map<String, dynamic>> _wildlifeRiskCache = {};
  List<Map<String, dynamic>> _activeEmergencies = [];
  bool _showEmergencyBanner = false;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(28.6139, 77.2090),
    zoom: 14,
    tilt: 60,
    bearing: 30,
  );

  bool _showSensitiveOverlay = false;
  bool _showHeatmap = false;
  bool _mapReady = false;

  Future<void> _checkAndShowAchievements() async {
    try {
      final userImpact = await _reportService.fetchImpactStats();
      final achievements = AchievementService.calculateAchievements(userImpact);
      
      final prefs = await SharedPreferences.getInstance();
      final unlockedIds = prefs.getStringList('unlocked_achievements') ?? [];
      
      for (final achievement in achievements) {
        if (achievement.unlocked && !unlockedIds.contains(achievement.id)) {
          if (mounted) {
            AchievementPopup.show(
              context,
              title: achievement.title,
              icon: achievement.icon,
            );
          }
          unlockedIds.add(achievement.id);
        }
      }
      
      await prefs.setStringList('unlocked_achievements', unlockedIds);
    } catch (e) {
      print('Error checking achievements: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      _initializeLocation();
      _subscribeToReports();
      _fetchForestAlerts();
      _fetchActiveEmergencies();
    } catch (e, stackTrace) {
      print('ExploreScreen init error: $e');
      print('Stack: $stackTrace');
    }
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      print('Location permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('Location permission after request: $permission');
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission required. Centering on default location.")),
          );
        }
        // Center on Chennai default location
        _currentLatLng = const LatLng(13.0827, 80.2707);
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentLatLng!,
                zoom: 12,
              ),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLatLng = LatLng(position.latitude, position.longitude);
      print('User location fetched: lat=${position.latitude} lng=${position.longitude}');

      setState(() {
        _locationText =
            "Lat: ${position.latitude.toStringAsFixed(4)}, "
            "Lng: ${position.longitude.toStringAsFixed(4)}";
      });

      if (_mapController != null && _currentLatLng != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentLatLng!,
              zoom: 16,
              tilt: 60,
              bearing: 30,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Location fetch error: $e');
      print('Location fetch stack: $stackTrace');
      // Center on default location on error
      _currentLatLng = const LatLng(13.0827, 80.2707);
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentLatLng!,
              zoom: 12,
            ),
          ),
        );
      }
    }
  }

  void _goToCurrentLocation() async {
    if (_mapController == null || _currentLatLng == null) return;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentLatLng!,
          zoom: 16,
          tilt: 60,
        ),
      ),
    );
  }

  Future<void> _fetchForestAlerts() async {
    if (_currentLatLng == null) return;

    try {
      final alerts = await _forestService.fetchForestAlerts(
        lat: _currentLatLng!.latitude,
        lng: _currentLatLng!.longitude,
      );

      if (alerts.isNotEmpty && mounted) {
        setState(() {
          _showSensitiveOverlay = true;
        });
      }
    } catch (e) {
      print('Forest alerts error: $e');
    }
  }

  Future<void> _fetchActiveEmergencies() async {
    try {
      final emergencies = await _emergencyService.fetchActiveEmergencies();
      
      // Filter emergencies within 5km
      final nearbyEmergencies = <Map<String, dynamic>>[];
      if (_currentLatLng != null) {
        for (var emergency in emergencies) {
          final lat = emergency['lat'] as double? ?? 0.0;
          final lng = emergency['lng'] as double? ?? 0.0;
          final distance = Geolocator.distanceBetween(
            _currentLatLng!.latitude,
            _currentLatLng!.longitude,
            lat,
            lng,
          );
          if (distance <= 5000) {
            nearbyEmergencies.add(emergency);
          }
        }
      }

      setState(() {
        _activeEmergencies = nearbyEmergencies;
        _showEmergencyBanner = nearbyEmergencies.isNotEmpty;
      });
    } catch (e) {
      print('Fetch emergencies error: $e');
    }
  }

  void _subscribeToReports() {
    try {
      _reportsSubscription = _reportService.streamReports().listen((reports) {
        setState(() {
          // Clear markers except forest alert
          _markers.removeWhere((marker) => marker.markerId.value != 'forest_alert_cluster');
          _circles.clear();
          
          for (final report in reports) {
            // Add heatmap circles if enabled
            if (_showHeatmap) {
              _circles.add(Circle(
                circleId: CircleId(report.id),
                center: LatLng(report.lat, report.lng),
                radius: 150,
                fillColor: report.type == 'dumping'
                    ? Colors.red.withOpacity(0.25)
                    : Colors.green.withOpacity(0.25),
                strokeColor: Colors.transparent,
                strokeWidth: 0,
              ));
            }
            
            // Determine marker color based on type and properties
            double hue;
            bool isHighRisk = false;
            
            if (report.isEmergency == true) {
              hue = BitmapDescriptor.hueRed;
            } else if (report.type == 'cleanup_event') {
              hue = BitmapDescriptor.hueGreen;
            } else if (report.type == 'dumping') {
              hue = BitmapDescriptor.hueRed;
              isHighRisk = (report.severity ?? 0) > 3;
            } else if (report.isSensitive == true) {
              hue = BitmapDescriptor.hueViolet;
            } else if (isHighRisk) {
              hue = BitmapDescriptor.hueOrange;
            } else {
              hue = BitmapDescriptor.hueAzure;
            }

            // Add marker (only if heatmap is not shown)
            if (!_showHeatmap) {
              _markers.add(
                Marker(
                  markerId: MarkerId(report.id),
                position: LatLng(report.lat, report.lng),
                icon: BitmapDescriptor.defaultMarkerWithHue(hue),
                onTap: () => _showReportDetails(report),
              ),
              );
            }

            // Add risk radius circle for dumping reports
            if (report.type == 'dumping' && report.severity != null) {
              final severity = report.severity!;
              final radius = severity * 50.0; // meters
              
              Color riskColor;
              if (severity >= 4) {
                riskColor = Colors.red;
              } else if (severity >= 3) {
                riskColor = Colors.orange;
              } else {
                riskColor = Colors.yellow;
              }

              _circles.add(
                Circle(
                  circleId: CircleId('risk_${report.id}'),
                  center: LatLng(report.lat, report.lng),
                  radius: radius,
                  fillColor: riskColor.withOpacity(0.2),
                  strokeColor: riskColor.withOpacity(0.5),
                  strokeWidth: 2,
                ),
              );
            }
          }
        });
      }, onError: (e) {
        print('Reports subscription error: $e');
      });
    } catch (e) {
      print('Reports subscription setup error: $e');
    }
  }

  Future<void> _cleanThisDump(Report report) async {
    final imagePicker = ImagePicker();
    final XFile? afterImage = await imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (afterImage == null) return;

    final afterFile = File(afterImage.path);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analyzing cleanup with AI verification...')),
      );
    }

    try {
      File beforeFile;
      if (report.photoBefore != null && report.photoBefore!.isNotEmpty) {
        if (report.photoBefore!.startsWith('http')) {
          final res = await http.get(Uri.parse(report.photoBefore!));
          final tempDir = Directory.systemTemp;
          beforeFile = File('${tempDir.path}/before_${report.id}.jpg');
          await beforeFile.writeAsBytes(res.bodyBytes);
        } else {
          beforeFile = File(report.photoBefore!);
        }
      } else {
        beforeFile = afterFile;
      }

      final verificationService = CleanupVerificationService();
      final isVerified = await verificationService.verifyCleanup(
        beforeFile,
        afterFile,
      );

      if (isVerified) {
        await _reportService.verifyReport(
          reportId: report.id,
          photoAfter: afterFile.path,
        );

        await _checkAndShowAchievements();

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('✅ Cleanup Verified!'),
              content: const Text('AI has verified that the waste has been removed. Thank you for making an impact!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('⚠️ Verification Failed'),
              content: const Text('Waste not fully removed. Try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error in cleanup verification: $e')),
        );
      }
    }
  }

  void _showReportDetails(Report report) {
    final isEmergency = report.isEmergency == true;
    final isFlagged = report.flagged == true;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (isEmergency) 
              const Icon(Icons.warning, color: Colors.red)
            else if (isFlagged)
              const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isEmergency 
                    ? '🚨 EMERGENCY: ${report.emergencyType ?? report.title ?? 'Unknown'}'
                    : (report.type == 'cleanup_event' 
                        ? (report.title ?? 'Cleanup Event') 
                        : report.type.toUpperCase()),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isFlagged) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '⚠️ This report was flagged as potentially not genuine',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
              if (report.description != null) ...[
                Text(report.description!),
                const SizedBox(height: 8),
              ],
              if (report.severity != null) ...[
                Text('Severity: ${report.severity}/5'),
                const SizedBox(height: 8),
              ],
              if (report.carbonEstimate != null) ...[
                Text('Carbon Impact: ${report.carbonEstimate!.toStringAsFixed(1)} kg CO₂e'),
                const SizedBox(height: 8),
              ],
              if (report.type == 'cleanup_event') ...[
                if (report.eventDate != null) ...[
                  Text('Date: ${report.eventDate}'),
                  const SizedBox(height: 8),
                ],
                Text('Participants: ${report.participantsCount ?? 0}'),
                const SizedBox(height: 8),
              ],
              Text('Status: ${report.status}'),
              const SizedBox(height: 8),
              Text('Organized by: ${report.createdByName}'),
              if (report.type == 'dumping') ...[
                const SizedBox(height: 16),
                const Text(
                  'Health Impact',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: _getHealthImpact(report),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              snapshot.data ?? 'No health impact data available',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Water Contamination Risk',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<Map<String, dynamic>>(
                  future: _getWaterBodyData(report),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final waterData = snapshot.data ?? {};
                    final atRisk = waterData['atRisk'] as bool? ?? false;
                    final nearby = waterData['nearby'] as int? ?? 0;
                    final bodies = waterData['bodies'] as List? ?? [];

                    if (!atRisk) {
                      return const Text(
                        'No water bodies detected within 500m',
                        style: TextStyle(fontSize: 14, color: Colors.green),
                      );
                    }

                    final bodyNames = bodies
                        .map((b) => b['name'] as String? ?? 'Water body')
                        .take(3)
                        .join(', ');

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.water_damage, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '⚠️ Water Contamination Risk - $nearby water body/bodies within 500m: $bodyNames',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '+2 severity flag',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Wildlife Impact',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<Map<String, dynamic>>(
                future: _getSpeciesData(report),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  final speciesData = snapshot.data ?? {};
                  final count = speciesData['count'] as int? ?? 0;
                  final species = speciesData['species'] as List? ?? [];

                  if (count == 0) {
                    return const Text(
                      'No threatened species data available',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count threatened species observed nearby in last year',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (count > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'This waste may harm local wildlife',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...species.take(5).map((s) {
                          final name = s['name'] as String? ?? 'Unknown';
                          final iconicTaxon = s['iconicTaxon'] as String? ?? 'Animal';
                          IconData speciesIcon;
                          if (iconicTaxon.toLowerCase().contains('bird')) {
                            speciesIcon = Icons.flight;
                          } else if (iconicTaxon.toLowerCase().contains('mammal')) {
                            speciesIcon = Icons.pets;
                          } else if (iconicTaxon.toLowerCase().contains('reptile')) {
                            speciesIcon = Icons.cruelty_free;
                          } else if (iconicTaxon.toLowerCase().contains('amphibian')) {
                            speciesIcon = Icons.terrain;
                          } else if (iconicTaxon.toLowerCase().contains('insect')) {
                            speciesIcon = Icons.bug_report;
                          } else {
                            speciesIcon = Icons.eco;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(speciesIcon, size: 16, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        const Text(
                          'Wildlife Risk Assessment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder(
                          future: WildlifeAlertService.assessWildlifeRisk(
                            lat: report.lat,
                            lng: report.lng,
                            wasteType: report.aiClassification ?? report.type,
                            severity: report.severity ?? 1,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            final riskData = snapshot.data;
                            if (riskData == null) {
                              return const Text('Unable to assess risk');
                            }
                            final riskScore = riskData['riskScore'] as int? ?? 0;
                            final level = riskData['level'] as String? ?? 'UNKNOWN';
                            final action = riskData['action'] as String? ?? '';
                            final aiAdvice = riskData['aiAdvice'] as String?;

                            Color levelColor;
                            if (level == 'CRITICAL') {
                              levelColor = Colors.red;
                            } else if (level == 'HIGH') {
                              levelColor = Colors.orange;
                            } else if (level == 'MODERATE') {
                              levelColor = Colors.yellow;
                            } else {
                              levelColor = Colors.green;
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: levelColor.withValues(alpha: 0.1),
                                    border: Border.all(color: levelColor),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Risk Level: $level',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: levelColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '($riskScore/100)',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Recommended: $action'),
                                if (aiAdvice != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      border: Border.all(color: Colors.blue),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'AI Advice: $aiAdvice',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              // Composting Options for organic waste
              if (report.type == 'dumping' && CompostingService.isCompostable(report.aiClassification ?? report.type))
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.compost, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Composting Options',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('This waste can be composted! Learn how...'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showCompostingDialog(report),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('View Composting Guide'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              // Nearest Recycling for non-organic waste
              if (report.type == 'dumping' && !CompostingService.isCompostable(report.aiClassification ?? report.type))
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.recycling, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Nearest Recycling',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<Map<String, dynamic>>(
                        future: RecyclingRouteService.findNearestFacility(
                          lat: report.lat,
                          lng: report.lng,
                          wasteType: report.aiClassification ?? report.type,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          final result = snapshot.data;
                          if (result == null || result['found'] != true) {
                            return Text(
                              result?['message'] as String? ?? 'No recycling facilities found nearby',
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          final facility = result['facility'] as Map<String, dynamic>?;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Facility: ${facility?['name'] ?? 'Unknown'}'),
                              Text('Distance: ${((facility?['distance'] as double?) ?? 0.0).toStringAsFixed(2)} km'),
                              Text('${result['totalNearby']} facilities within 5km'),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final url = result['directionsUrl'] as String?;
                                  if (url != null && await canLaunchUrl(Uri.parse(url))) {
                                    await launchUrl(Uri.parse(url));
                                  }
                                },
                                icon: const Icon(Icons.directions),
                                label: const Text('Get Directions'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (report.type == 'dumping')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cleanThisDump(report);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Clean This Dump'),
            ),
          if (report.type == 'cleanup_event')
            ElevatedButton(
              onPressed: () async {
                await _reportService.joinEvent(report.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Successfully joined cleanup event!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Join Cleanup'),
            ),
        ],
      ),
    );
  }

  Future<String> _getHealthImpact(Report report) async {
    if (_healthImpactCache.containsKey(report.id)) {
      return _healthImpactCache[report.id]!;
    }

    final wasteType = report.aiClassification ?? report.type;
    final severity = report.severity ?? 1;
    final daysOld = DateTime.now().difference(report.createdAt).inDays;

    final impact = await HealthImpactService.getHealthImpact(
      wasteType: wasteType,
      severity: severity,
      daysOld: daysOld,
    );

    _healthImpactCache[report.id] = impact;
    return impact;
  }

  Future<Map<String, dynamic>> _getWaterBodyData(Report report) async {
    if (_waterBodyCache.containsKey(report.id)) {
      return _waterBodyCache[report.id]!;
    }

    final waterData = await WaterBodyService.checkNearbyWater(
      report.lat,
      report.lng,
    );

    _waterBodyCache[report.id] = waterData;
    return waterData;
  }

  Future<Map<String, dynamic>> _getSpeciesData(Report report) async {
    if (_speciesCache.containsKey(report.id)) {
      return _speciesCache[report.id]!;
    }

    final speciesData = await SpeciesImpactService.fetchNearbySpecies(
      report.lat,
      report.lng,
    );

    _speciesCache[report.id] = speciesData;
    return speciesData;
  }

  void _showCompostingDialog(Report report) {
    final location = '${report.lat.toStringAsFixed(2)}, ${report.lng.toStringAsFixed(2)}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.compost, color: Colors.green),
            SizedBox(width: 8),
            Text('Composting Guide'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...CompostingService.quickTips.map((tip) {
                  final icon = _getCompostIcon(tip['icon'] as String);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 20, color: tip['icon'] == 'warning' ? Colors.red : Colors.green),
                              const SizedBox(width: 8),
                              Text(tip['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Items: ${(tip['items'] as List).join(', ')}'),
                          Text('Time: ${tip['time']}'),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Text('AI Personalized Guide:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: CompostingService.getPersonalizedGuide(
                    wasteType: report.aiClassification ?? report.type,
                    location: location,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    return Text(snapshot.data ?? 'Unable to load guide');
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getCompostIcon(String icon) {
    switch (icon) {
      case 'kitchen': return Icons.restaurant;
      case 'yard': return Icons.park;
      case 'paper': return Icons.description;
      case 'warning': return Icons.warning;
      default: return Icons.eco;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Emergency Banner
          if (_showEmergencyBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.red,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠️ ${_activeEmergencies.length} active emergency/emergencies nearby. Tap to view.',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_activeEmergencies.isNotEmpty && _currentLatLng != null) {
                          final nearest = _activeEmergencies[0];
                          final lat = nearest['lat'] as double? ?? 0.0;
                          final lng = nearest['lng'] as double? ?? 0.0;
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(lat, lng),
                              16,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.center_focus_strong, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            markers: _markers,
            circles: _circles,
            onMapCreated: (controller) {
              print('Map controller created successfully');
              _mapController = controller;
              setState(() {
                _mapReady = true;
              });

              if (_currentLatLng != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _currentLatLng!,
                      zoom: 16,
                      tilt: 60,
                      bearing: 30,
                    ),
                  ),
                );
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            tiltGesturesEnabled: true,
            zoomControlsEnabled: false,
          ),
          // Loading indicator
          if (!_mapReady)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading map...'),
                ],
              ),
            ),
          // Return to My Location Button
          Positioned(
            right: 16,
            bottom: 160,
            child: FloatingActionButton(
              heroTag: 'heatmap_button',
              mini: true,
              backgroundColor: _showHeatmap ? const Color(0xFF00C896) : Colors.white,
              onPressed: () {
                setState(() => _showHeatmap = !_showHeatmap);
              },
              child: Icon(
                Icons.blur_on,
                color: _showHeatmap ? Colors.white : Colors.black,
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              heroTag: 'location_button',
              onPressed: _goToCurrentLocation,
              backgroundColor: AppColors.card,
              elevation: 4,
              child: const Icon(
                Icons.my_location,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}