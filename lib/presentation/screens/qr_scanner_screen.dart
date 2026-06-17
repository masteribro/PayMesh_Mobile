import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../widgets/scanner_overlay.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    _scanned = true;
    final raw = barcode!.rawValue!;

    String userId = raw;
    String? username;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['type'] == 'paymesh_id') {
        userId = data['userId'] as String;
        username = data['username'] as String?;
      }
    } catch (_) {
      // raw value is a plain userId string — use as-is
    }

    Navigator.pop(context, {'userId': userId, 'username': username});
  }

  void _toggleTorch() {
    _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Recipient QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon:
                Icon(_torchOn ? Icons.flashlight_on : Icons.flashlight_off),
            tooltip: 'Toggle torch',
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          const ScannerOverlay(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Point at a PayMesh QR code to set the recipient',
                style: TextStyle(color: Colors.white, fontSize: 13.sp),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
