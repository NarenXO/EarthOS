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
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _barcodeScanner = BarcodeScanner();
    _initializeCamera();
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
      print('Barcode scanner: camera initialized');

      if (mounted) {
        setState(() {});
        _startBarcodeDetection();
      }
    } catch (e) {
      print('Camera initialization error: $e');
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
      if (!_isScanning || _isProcessing) return;

      _isProcessing = true;
      print('Barcode scanner: processing frame');

      try {
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
      } catch (e) {
        _isProcessing = false;
      }
    });
  }

  Future<void> _processImage(InputImage inputImage) async {
    try {
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty && mounted && _isScanning) {
        _isScanning = false;
        final barcode = barcodes.first;
        final rawValue = barcode.rawValue;
        print('Barcode scanner: DETECTED: $rawValue');
        Navigator.pop(context, rawValue);
      }
    } catch (e) {
      print('Error processing barcode image: $e');
    } finally {
      _isProcessing = false;
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Align barcode within frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
