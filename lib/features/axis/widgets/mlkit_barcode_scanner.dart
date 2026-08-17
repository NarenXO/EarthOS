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
  String? _detectedBarcode;

  @override
  void initState() {
    super.initState();
    print('BarcodeScanner: initializing camera');
    _barcodeScanner = BarcodeScanner(formats: [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upca,
      BarcodeFormat.upce,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,
    ]);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      print('BarcodeScanner: available cameras: ${cameras.length}');
      
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
      print('BarcodeScanner: camera initialized, starting stream');

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
      print('BarcodeScanner: frame received size=${image.width}x${image.height}');

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
        print('BarcodeScanner: frame processing error: $e');
        _isProcessing = false;
      }
    });
    print('BarcodeScanner: camera started, streaming frames');
  }

  Future<void> _processImage(InputImage inputImage) async {
    try {
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty && mounted && _isScanning) {
        _isScanning = false;
        final barcode = barcodes.first;
        final rawValue = barcode.rawValue;
        print('BarcodeScanner: DETECTED type=${barcode.type} raw=$rawValue');
        
        setState(() {
          _detectedBarcode = rawValue;
        });
        
        // Brief delay to show the detected barcode before closing
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.pop(context, rawValue);
        }
      } else {
        print('BarcodeScanner: no barcode in this frame');
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
    print('BarcodeScanner: disposed');
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_detectedBarcode != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _detectedBarcode!,
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
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
                      child: Text(
                        _detectedBarcode ?? 'Point at product barcode',
                        style: const TextStyle(
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
