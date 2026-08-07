import 'package:flutter/material.dart';

class AppColors {

  // CORE
  static const Color primary = Color(0xFF0F8F6F);
  static const Color accent = Color(0xFF5EF2C5);
  static const Color glow = Color(0xFF8FFFD9);
  static const Color success = Color(0xFF42E6A4);
  static const Color danger = Color(0xFFFF5252);

  // BACKGROUND
  static const Color bgDark = Color(0xFF040404);
  static const Color bgMid = Color(0xFF07120E);
  static const Color bgDeep = Color(0xFF0A1A16);

  static const Color background = bgDark;

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgDark, bgMid, bgDeep],
  );

  // SURFACES
  static const Color surfaceDark = Color(0xFF0B1512);
  static const Color card = Color(0xFF0B1512);
  static const Color glass = Color(0x14FFFFFF);
  static const Color border = Color(0x22FFFFFF);

  // TEXT
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CBDB4);

  // ORB GRADIENT
  static const List<Color> orbGradient = [
    Color(0xFF0F8F6F),
    Color(0xFF5EF2C5),
    Color(0xFF8FFFD9),
  ];

  // GLOWS
  static List<BoxShadow> strongGlow = [
    BoxShadow(
      color: glow.withOpacity(0.6),
      blurRadius: 60,
      spreadRadius: 10,
    ),
  ];

  static List<BoxShadow> softGlow = [
    BoxShadow(
      color: accent.withOpacity(0.25),
      blurRadius: 30,
      spreadRadius: 6,
    ),
  ];
}