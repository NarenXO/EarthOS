/*
|--------------------------------------------------------------------------
| EarthOS
| File: explore_screen.dart
| Feature: Explore Module
| Author: Naren
|--------------------------------------------------------------------------
| Explore = Google Map + Hotspots + Sensitive Areas
|--------------------------------------------------------------------------
*/

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import 'package:geolocator/geolocator.dart';


class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {

  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
String _locationText = "Fetching location...";

@override
void initState() {
  super.initState();
  _initializeLocation();
}

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(28.6139, 77.2090), // Default: Delhi (change later dynamically)
    zoom: 14,
    tilt: 60,
    bearing: 30,
  );

  bool _showSensitiveOverlay = false;

Future<void> _requestLocationPermission() async {
  LocationPermission permission;

  permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    return;
  }
}

Future<void> _initializeLocation() async {
  await _requestLocationPermission();

  Position position = await Geolocator.getCurrentPosition(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [

          // ===============================
          // GOOGLE MAP
          // ===============================
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
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

          // ===============================
          // LOCATION CHIP
          // ===============================
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: _buildLocationChip(),
          ),

          // ===============================
          // SENSITIVE ZONE ALERT
          // ===============================
          if (_showSensitiveOverlay)
            Positioned(
              top: 110,
              left: 20,
              right: 20,
              child: _buildSensitiveZoneBanner(),
            ),

          // ===============================
          // MAP CONTROLS
          // ===============================
          Positioned(
            bottom: 140,
            right: 20,
            child: Column(
              children: [
                _buildMapControlButton(
                  icon: Icons.layers_outlined,
                  onTap: () {
                    setState(() {
                      _showSensitiveOverlay = !_showSensitiveOverlay;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildMapControlButton(
                  icon: Icons.my_location,
                  onTap: _goToCurrentLocation,
                ),
              ],
            ),
          ),

          // ===============================
          // BOTTOM SHEET
          // ===============================
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomSheet(context),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MOVE CAMERA TO USER
  // =========================================================
  void _goToCurrentLocation() async {
    if (_mapController == null) return;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: LatLng(28.6139, 77.2090), // Replace with real location later
          zoom: 16,
          tilt: 60,
        ),
      ),
    );
  }

  // =========================================================
  // LOCATION CHIP
  // =========================================================
  Widget _buildLocationChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              _locationText,
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SENSITIVE ZONE BANNER
  // =========================================================
  Widget _buildSensitiveZoneBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.danger),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Sensitive Zone Nearby",
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MAP BUTTON
  // =========================================================
  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  // =========================================================
  // BOTTOM SHEET
  // =========================================================
  Widget _buildBottomSheet(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 4),
          Text(
            "Nearby Activity",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Live reports and bounty zones will appear here",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}