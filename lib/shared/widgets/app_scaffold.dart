/*
|--------------------------------------------------------------------------
| EarthOS
| Floating Glass Dock Navigation
|--------------------------------------------------------------------------
*/

import 'package:flutter/material.dart';
import 'package:earthos/core/constants/app_colors.dart';
import 'package:earthos/features/explore/explore_screen.dart';
import 'package:earthos/features/report/report_screen.dart';
import 'package:earthos/features/axis/axis_screen.dart';
import 'package:earthos/features/impact/impact_screen.dart';
import 'package:earthos/features/profile/profile_screen.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {

  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ExploreScreen(),
    ReportScreen(),
    AxisScreen(),
    ImpactScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        // ===============================
        // MAIN CONTENT
        // ===============================

        IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),

        // ===============================
        // FLOATING DOCK
        // ===============================

        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: _buildFloatingDock(),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // FLOATING GLASS DOCK
  // =========================================================

  Widget _buildFloatingDock() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softGlow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dockItem(Icons.public, 0),
          const SizedBox(width: 32),
          _dockItem(Icons.blur_circular, 1),
          const SizedBox(width: 32),
          _dockItem(Icons.smart_toy, 2),
          const SizedBox(width: 32),
          _dockItem(Icons.insights, 3),
          const SizedBox(width: 32),
          _dockItem(Icons.person, 4),
        ],
      ),
    );
  }

  // =========================================================
  // DOCK ITEM
  // =========================================================

  Widget _dockItem(IconData icon, int index) {

    final bool isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 350),
        curve: Curves.elasticOut,
        scale: isActive ? 1.3 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppColors.primary.withOpacity(0.2)
                : Colors.transparent,
            boxShadow: isActive ? AppColors.strongGlow : [],
          ),
          child: Icon(
            icon,
            size: 26,
            color: isActive
                ? AppColors.glow
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}