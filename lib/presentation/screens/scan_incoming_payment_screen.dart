import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
      _showError('This is not a payment QR. Use "Scan Recipient QR" to find people to pay.');
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
      receiverId: receiverId ?? "",
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
    // Reset scan after showing error so user can try again
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
            Navigator.pop(context); // close sheet
            Navigator.pop(context, true); // return to caller with success
          }
        },
        onReject: () {
          Navigator.pop(context); // close sheet only
          setState(() => _scanned = false); // allow re-scan
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
            icon: Icon(_torchOn ? Icons.flashlight_on : Icons.flashlight_off),
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
              margin: const EdgeInsets.only(bottom: 60),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Point at the sender\'s Payment QR code',
                style: TextStyle(color: Colors.white, fontSize: 14),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_downward,
              color: Color(0xFF10B981),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Incoming Payment',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'From: $senderName',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            '₦${FormatUtil.formatCurrencyWithComma(amount)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'TX: ${FormatUtil.formatTransactionId(txId)}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Funds are pending — will be confirmed when either '
                    'party syncs to the server.',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFFB45309)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side:
                        const BorderSide(color: Color(0xFFEF4444), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
