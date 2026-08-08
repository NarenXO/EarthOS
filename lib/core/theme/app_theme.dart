/*
|--------------------------------------------------------------------------
| EarthOS Design System
| Premium Typography + Transparent Base
|--------------------------------------------------------------------------
*/

import 'package:flutter/material.dart';
import 'package:earthos/core/constants/app_colors.dart';

class AppTheme {

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: AppColors.primary,
      fontFamily: "Inter",

      textTheme: const TextTheme(

        // ===============================
        // MANROPE HEADLINES
        // ===============================

        displayLarge: TextStyle(
          fontFamily: "Manrope",
          fontWeight: FontWeight.w700,
          fontSize: 42,
          height: 1.1,
          letterSpacing: -1.2,
          color: AppColors.textPrimary,
        ),

        headlineLarge: TextStyle(
          fontFamily: "Manrope",
          fontWeight: FontWeight.w700,
          fontSize: 34,
          height: 1.15,
          letterSpacing: -0.8,
          color: AppColors.textPrimary,
        ),

        headlineMedium: TextStyle(
          fontFamily: "Manrope",
          fontWeight: FontWeight.w600,
          fontSize: 26,
          height: 1.2,
          letterSpacing: -0.4,
          color: AppColors.textPrimary,
        ),

        // ===============================
        // INTER BODY
        // ===============================

        bodyLarge: TextStyle(
          fontFamily: "Inter",
          fontWeight: FontWeight.w400,
          fontSize: 16,
          height: 1.5,
          color: AppColors.textPrimary,
        ),

        bodyMedium: TextStyle(
          fontFamily: "Inter",
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 1.4,
          color: AppColors.textSecondary,
        ),

        labelLarge: TextStyle(
          fontFamily: "Inter",
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.5,
          color: AppColors.textPrimary,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
      ),
    );
  }
}