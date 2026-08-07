/*
|--------------------------------------------------------------------------
| EarthOS
| Application Entry Point
|--------------------------------------------------------------------------
*/

import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_scaffold.dart';
import 'shared/widgets/animated_background.dart';

void main() {
  runApp(const EarthOSApp());
}

class EarthOSApp extends StatelessWidget {
  const EarthOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AnimatedBackground(
        child: AppScaffold(),
      ),
    );
  }
}