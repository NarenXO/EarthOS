/*
|--------------------------------------------------------------------------
| EarthOS
| File: explore_screen.dart
| Feature: Explore Module
|--------------------------------------------------------------------------
*/

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:earthos/core/constants/app_colors.dart';
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
  final Set<Marker> _markers = {};
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
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }
  }

  Future<void> _initializeLocation() async {
    await _requestLocationPermission();

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _currentLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _locationText =
          "Lat: ${position.latitude.toStringAsFixed(4)}, "
          "Lng: ${position.longitude.toStringAsFixed(4)}";
    });

    if (_mapController != null) {
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

  void _subscribeToReports() {
    _reportsSubscription = _reportService.streamReports().listen((reports) {
      setState(() {
        _markers.clear();
        for (final report in reports) {
          _markers.add(
            Marker(
              markerId: MarkerId(report.id),
              position: LatLng(report.lat, report.lng),
              infoWindow: InfoWindow(
                title: report.type,
                snippet: 'Status: ${report.status}',
              ),
            ),
          );
        }
      });
    });
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
            myLocationButtonEnabled: false,
            compassEnabled: true,
            tiltGesturesEnabled: true,
            zoomControlsEnabled: false,
          ),
        ],
      ),
    );
  }
}