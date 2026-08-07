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
import '../../core/constants/app_colors.dart';

class ImpactScreen extends StatelessWidget {
  const ImpactScreen({super.key});

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
            // GLOBAL IMPACT SECTION
            // ===============================
            Text(
              "Global Impact",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildImpactGrid(),

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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // GLOBAL IMPACT GRID
  // =========================================================
  Widget _buildImpactGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: const [
        _ImpactCard(title: "Reports", value: "124"),
        _ImpactCard(title: "CO₂e Prevented", value: "2.4T"),
        _ImpactCard(title: "Active Bounties", value: "18"),
        _ImpactCard(title: "Sensitive Zones", value: "7"),
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