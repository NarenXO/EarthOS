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

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/vision_service.dart';
import '../../core/services/user_identity_service.dart';
import '../../core/services/cleanup_verification_service.dart';
import 'services/report_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _orbController;
  final ImagePicker _imagePicker = ImagePicker();
  final VisionService _visionService = VisionService();
  final ReportService _reportService = ReportService();
  final UserIdentityService _userIdentityService = UserIdentityService();
  final CleanupVerificationService _verificationService = CleanupVerificationService();

  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _isVerifying = false;
  bool _isVerificationMode = false;
  Position? _currentPosition;
  String? _reportIdToVerify;
  File? _beforeImageForVerification;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      await _classifyAndSubmit();
    }
  }

  Future<void> _classifyAndSubmit() async {
    if (_selectedImage == null || _currentPosition == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _visionService.classifyWaste(_selectedImage!);

      final wasteType = result['waste_type'] as String?;
      final severity = result['severity'] as int?;

      final user = await _userIdentityService.getOrCreateUser();

      await _reportService.createReport(
        type: wasteType ?? 'unknown',
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        createdBy: user.id,
        createdByName: user.name,
        photoBefore: _selectedImage!.path,
        aiClassification: wasteType,
        severity: severity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully'),
          ),
        );
      }

      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _pickAfterImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      await _verifyCleanup();
    }
  }

  Future<void> _verifyCleanup() async {
    if (_selectedImage == null || _beforeImageForVerification == null) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final isCleaned = await _verificationService.verifyCleanup(
        _beforeImageForVerification!,
        _selectedImage!,
      );

      if (isCleaned && _reportIdToVerify != null) {
        await _reportService.verifyReport(
          reportId: _reportIdToVerify!,
          photoAfter: _selectedImage!.path,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cleanup verified successfully'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification failed: cleanup not confirmed'),
            ),
          );
        }
      }

      setState(() {
        _selectedImage = null;
        _beforeImageForVerification = null;
        _reportIdToVerify = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: $e'),
          ),
        );
      }
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  void _startVerificationMode(String reportId, File beforeImage) {
    setState(() {
      _reportIdToVerify = reportId;
      _beforeImageForVerification = beforeImage;
      _isVerificationMode = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification mode: Take after photo'),
        ),
      );
    }
  }

  void _exitVerificationMode() {
    setState(() {
      _isVerificationMode = false;
      _reportIdToVerify = null;
      _beforeImageForVerification = null;
    });
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

          // ===============================
          // LOADING OVERLAY
          // ===============================
          if (_isAnalyzing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing waste...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // ===============================
          // VERIFICATION LOADING OVERLAY
          // ===============================
          if (_isVerifying)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Verifying cleanup...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
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
                    _buildInputButton(
                      Icons.camera_alt_outlined,
                      onTap: _isVerificationMode ? _pickAfterImage : _pickImage,
                    ),
                    _buildInputButton(Icons.keyboard_outlined),
                    if (_isVerificationMode)
                      _buildInputButton(Icons.close, onTap: _exitVerificationMode)
                    else
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
  Widget _buildInputButton(IconData icon, {VoidCallback? onTap}) {
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
}