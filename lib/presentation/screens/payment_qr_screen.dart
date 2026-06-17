import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../domain/utils/format_util.dart';

/// Shown to the SENDER after an offline transaction is created.
/// Displays a QR code encoding the full signed transaction payload.
/// The recipient scans this QR to receive the funds on their device.
class PaymentQrScreen extends StatelessWidget {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String recipientName;
  final double amount;
  final String timestamp;
  final String signature;

  const PaymentQrScreen({
    super.key,
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.recipientName,
    required this.amount,
    required this.timestamp,
    required this.signature,
  });

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({
      'type': 'paymesh_payment',
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'amount': amount,
      'timestamp': timestamp,
      'signature': signature,
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Payment QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Let the recipient scan this',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: EdgeInsets.all(6.w),
                child: Column(
                  children: [
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 62.w,
                      backgroundColor: Colors.white,
                    ),
                    SizedBox(height: 2.5.h),
                    Text(
                      '₦${FormatUtil.formatCurrencyWithComma(amount)}',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'To: $recipientName',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'TX: ${FormatUtil.formatTransactionId(id)}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4.h),

              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: const Color(0xFFF59E0B), size: 4.5.w),
                    SizedBox(width: 2.5.w),
                    Expanded(
                      child: Text(
                        'This transaction is saved on your device. '
                        'It will sync to the server automatically '
                        "when you're back online.",
                        style: TextStyle(
                          color: const Color(0xFFF59E0B),
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
