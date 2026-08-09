/*
|--------------------------------------------------------------------------
| EarthOS
| File: mlkit_barcode_scanner.dart
| Feature: MLKit Barcode Scanner
| Author: Naren
|--------------------------------------------------------------------------
| Barcode scanner using camera and ML Kit
|--------------------------------------------------------------------------
*/
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class MLKitBarcodeScanner extends StatefulWidget {
  const MLKitBarcodeScanner({super.key});

  @override
  State<MLKitBarcodeScanner> createState() => _MLKitBarcodeScannerState();
}

class _MLKitBarcodeScannerState extends State<MLKitBarcodeScanner> {
  CameraController? _cameraController;
  late final BarcodeScanner _barcodeScanner;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _barcodeScanner = BarcodeScanner();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          Navigator.pop(context, null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available')),
          );
        }
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {});
        _startBarcodeDetection();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context, null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  void _startBarcodeDetection() {
    _cameraController!.startImageStream((CameraImage image) {
      if (!_isScanning) return;

      // Use NV21 format directly for ML Kit
      final inputImage = InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      _processImage(inputImage);
    });
  }

  Future<void> _processImage(InputImage inputImage) async {
    try {
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty && mounted) {
        _isScanning = false;
        final barcode = barcodes.first;
        Navigator.pop(context, barcode.rawValue);
      }
    } catch (e) {
      // Ignore processing errors
    }
  }

  @override
  void dispose() {
    _isScanning = false;
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Stack(
              children: [
                CameraPreview(_cameraController!),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Align barcode within frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        backgroundColor: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
