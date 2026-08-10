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

import 'package:earthos/core/constants/app_colors.dart';
import 'package:earthos/core/services/forest_service.dart';
import 'package:earthos/core/services/cleanup_verification_service.dart';
import 'package:earthos/features/report/services/report_service.dart';
import 'package:earthos/features/report/models/report_model.dart';

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
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  StreamSubscription<List<Report>>? _reportsSubscription;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(28.6139, 77.2090),
    zoom: 14,
    tilt: 60,
    bearing: 30,
  );

  bool _showSensitiveOverlay = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _subscribeToReports();
    _fetchForestAlerts();
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission required")),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLatLng = LatLng(position.latitude, position.longitude);

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
    } catch (e) {
      print('Location fetch error: $e');
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

      final alertCount = alerts['alertCount'] as int? ?? 0;
      
      if (alertCount > 0 && _currentLatLng != null) {
        // Add a forest alert marker near user location
        // Since we don't have exact geometry, we place a marker slightly offset
        setState(() {
          _markers.add(
            Marker(
              markerId: const MarkerId('forest_alert_cluster'),
              position: LatLng(
                _currentLatLng!.latitude + 0.01,
                _currentLatLng!.longitude + 0.01,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
              infoWindow: InfoWindow(
                title: 'Forest Alerts',
                snippet: '$alertCount alerts detected in this area',
              ),
            ),
          );
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  void _subscribeToReports() {
    _reportsSubscription = _reportService.streamReports().listen((reports) {
      setState(() {
        // Clear markers except forest alert
        _markers.removeWhere((marker) => marker.markerId.value != 'forest_alert_cluster');
        _circles.clear();
        for (final report in reports) {
          // Determine marker color based on type and properties
          double hue;
          bool isHighRisk = false;
          
          if (report.type == 'cleanup_event') {
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

          // Add marker
          _markers.add(
            Marker(
              markerId: MarkerId(report.id),
              position: LatLng(report.lat, report.lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
              onTap: () => _showReportDetails(report),
            ),
          );

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
    });
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
        reportId: report.id,
      );

      if (isVerified) {
        await _reportService.verifyReport(
          reportId: report.id,
          photoAfter: afterFile.path,
        );

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.type == 'cleanup_event' 
            ? (report.title ?? 'Cleanup Event') 
            : report.type.toUpperCase()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            markers: _markers,
            circles: _circles,
            onMapCreated: (controller) {
              _mapController = controller;

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
          // Return to My Location Button
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