/*
|--------------------------------------------------------------------------
| EarthOS
| File: report_screen.dart
| Feature: Report Module
| Author: Naren
|--------------------------------------------------------------------------
| AXIS AI Reporting Interface
|--------------------------------------------------------------------------
*/

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [

          // ===============================
          // CENTER ORB
          // ===============================
          Center(
            child: AnimatedBuilder(
              animation: _orbController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _orbController.value * 6.3,
                  child: child,
                );
              },
              child: _buildAxisOrb(),
            ),
          ),

          // ===============================
          // TOP TITLE
          // ===============================
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  AppConfig.aiName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  "Environmental Intelligence Core",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // ===============================
          // GLASS CHAT PANEL
          // ===============================
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildGlassChatPanel(context),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // AXIS ORB
  // =========================================================
  Widget _buildAxisOrb() {
    return Container(
      height: 200,
      width: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: AppColors.orbGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 60,
            spreadRadius: 12,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.blur_circular,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  // =========================================================
  // GLASS CHAT PANEL
  // =========================================================
  Widget _buildGlassChatPanel(BuildContext context) {
    return Container(
      height: 260,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.glass,
            child: Column(
              children: [
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),

                // ===============================
                // CHAT MESSAGE PREVIEW
                // ===============================
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "AXIS: Describe the environmental issue or capture a photo.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ===============================
                // INPUT CONTROLS
                // ===============================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInputButton(Icons.camera_alt_outlined),
                    _buildInputButton(Icons.keyboard_outlined),
                    _buildInputButton(Icons.mic_none),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // INPUT BUTTON
  // =========================================================
  Widget _buildInputButton(IconData icon) {
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        color: AppColors.card,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }
}