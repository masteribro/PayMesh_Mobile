import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/incoming_transaction_service.dart';
import '../../domain/utils/format_util.dart';
import '../widgets/scanner_overlay.dart';

/// Shown to the RECIPIENT. They scan the sender's Payment QR code.
/// The app validates that the transaction is addressed to them,
/// then stores it locally so it appears immediately in their balance.
class ScanIncomingPaymentScreen extends StatefulWidget {
  const ScanIncomingPaymentScreen({super.key});

  @override
  State<ScanIncomingPaymentScreen> createState() =>
      _ScanIncomingPaymentScreenState();
}

class _ScanIncomingPaymentScreenState
    extends State<ScanIncomingPaymentScreen> {
  final _controller = MobileScannerController();
  final _authService = AuthService();
  final _incomingService = IncomingTransactionService();

  bool _scanned = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      _showError('Not a valid PayMesh QR code.');
      return;
    }

    if (data['type'] != 'paymesh_payment') {
      _showError(
          'This is not a payment QR. Use "Scan Recipient QR" to find people to pay.');
      return;
    }

    final currentUserId = await _authService.getUserId();
    if (currentUserId == null) {
      _showError('You are not logged in.');
      return;
    }

    final receiverId = data['receiverId'] as String?;
    if (receiverId != currentUserId) {
      _showError('This payment is not addressed to you.');
      return;
    }

    _scanned = true;

    final id = data['id'] as String;
    final senderId = data['senderId'] as String;
    final senderName = (data['senderName'] as String?) ?? 'Unknown';
    final amount = (data['amount'] as num).toDouble();
    final timestamp = data['timestamp'] as String;
    final signature = data['signature'] as String;

    if (!mounted) return;
    _showConfirmationSheet(
      id: id,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId ?? '',
      amount: amount,
      timestamp: timestamp,
      signature: signature,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _scanned = false);
    });
  }

  void _showConfirmationSheet({
    required String id,
    required String senderId,
    required String senderName,
    required String receiverId,
    required double amount,
    required String timestamp,
    required String signature,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ConfirmSheet(
        senderName: senderName,
        amount: amount,
        txId: id,
        onAccept: () async {
          await _incomingService.saveIncoming(
            id: id,
            senderId: senderId,
            receiverId: receiverId,
            amount: amount,
            timestamp: timestamp,
            signature: signature,
          );
          if (mounted) {
            Navigator.pop(context);
            Navigator.pop(context, true);
          }
        },
        onReject: () {
          Navigator.pop(context);
          setState(() => _scanned = false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Incoming Payment'),
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
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Point at the sender\'s Payment QR code',
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

class _ConfirmSheet extends StatelessWidget {
  final String senderName;
  final double amount;
  final String txId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ConfirmSheet({
    required this.senderName,
    required this.amount,
    required this.txId,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16.w,
            height: 16.w,
            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_downward,
              color: const Color(0xFF10B981),
              size: 9.w,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Incoming Payment',
            style:
                TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'From: $senderName',
            style: TextStyle(
                color: const Color(0xFF6B7280), fontSize: 13.sp),
          ),
          SizedBox(height: 1.5.h),
          Text(
            '₦${FormatUtil.formatCurrencyWithComma(amount)}',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'TX: ${FormatUtil.formatTransactionId(txId)}',
            style:
                TextStyle(fontSize: 10.sp, color: const Color(0xFF9CA3AF)),
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 3.5.w, color: const Color(0xFFF59E0B)),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Funds are pending — will be confirmed when either '
                    'party syncs to the server.',
                    style: TextStyle(
                        fontSize: 10.sp, color: const Color(0xFFB45309)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(
                        color: Color(0xFFEF4444), width: 2),
                    padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
