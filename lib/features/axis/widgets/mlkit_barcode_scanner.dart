import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool _detected = false;

  @override
  void initState() {
    super.initState();
    print('BarcodeScanner: mobile_scanner initialized');
  }

  @override
  void dispose() {
    _controller.dispose();
    print('BarcodeScanner: disposed');
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    
    print('BarcodeScanner: DETECTED raw=$code type=${barcodes.first.type}');
    setState(() => _detected = true);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context, code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                final torchState = state.torchState;
                switch (torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  default:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Scanner error: ${error.errorCode}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Scan target overlay
          Container(
            width: 280,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: _detected ? Colors.green : const Color(0xFF00C896),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          
          Positioned(
            bottom: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                _detected ? 'Barcode detected!' : 'Point at product barcode',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
