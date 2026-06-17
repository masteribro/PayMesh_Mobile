import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../domain/utils/format_util.dart';
import '../blocs/send_money/send_money_bloc.dart';
import '../widgets/section_card.dart';
import 'payment_qr_screen.dart';
import 'qr_scanner_screen.dart';

class SendMoneyScreen extends StatelessWidget {
  const SendMoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SendMoneyBloc(),
      child: const _SendMoneyView(),
    );
  }
}

class _SendMoneyView extends StatefulWidget {
  const _SendMoneyView();

  @override
  State<_SendMoneyView> createState() => _SendMoneyViewState();
}

class _SendMoneyViewState extends State<_SendMoneyView> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _scanQr(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result == null || !context.mounted) return;
    final userId = result['userId'] as String?;
    final username = result['username'] as String?;
    if (userId != null) {
      context
          .read<SendMoneyBloc>()
          .add(RecipientQrScanned(userId: userId, username: username));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipient set to ${username ?? userId}'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _showOfflineSuccessSheet(BuildContext context, SendMoneyState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16.w,
              height: 16.w,
              decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7), shape: BoxShape.circle),
              child: Icon(Icons.schedule,
                  color: const Color(0xFFF59E0B), size: 9.w),
            ),
            SizedBox(height: 2.h),
            Text('Queued!',
                style: TextStyle(
                    fontSize: 20.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 0.5.h),
            Text(
              'Saved locally — will sync when online',
              style: TextStyle(
                  color: const Color(0xFF9CA3AF), fontSize: 12.sp),
            ),
            SizedBox(height: 1.h),
            Text(
              '₦${FormatUtil.formatCurrencyWithComma(state.offlineAmount ?? 0)}',
              style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD97706)),
            ),
            SizedBox(height: 1.h),
            Text('To: ${state.offlineRecipientName ?? ''}',
                style: TextStyle(
                    color: const Color(0xFF6B7280), fontSize: 13.sp)),
            SizedBox(height: 0.5.h),
            Text(
                'TX: ${FormatUtil.formatTransactionId(state.offlineTxId ?? '')}',
                style: TextStyle(
                    fontSize: 11.sp, color: const Color(0xFF9CA3AF))),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2,
                      color: const Color(0xFF2563EB), size: 5.w),
                  SizedBox(width: 2.5.w),
                  Expanded(
                    child: Text(
                      'Show a QR so the recipient can receive the funds now — even offline.',
                      style: TextStyle(
                          fontSize: 11.sp, color: const Color(0xFF1D4ED8)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentQrScreen(
                        id: state.offlineTxId!,
                        senderId: state.offlineSenderId!,
                        senderName: state.offlineSenderName!,
                        receiverId: state.offlineReceiverId!,
                        recipientName: state.offlineRecipientName!,
                        amount: state.offlineAmount!,
                        timestamp: state.offlineTimestamp!,
                        signature: state.offlineSignature!,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Show Payment QR'),
              ),
            ),
            SizedBox(height: 1.h),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done (sync later)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSheet(BuildContext context, SendMoneyState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16.w,
              height: 16.w,
              decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5), shape: BoxShape.circle),
              child: Icon(Icons.check_circle,
                  color: const Color(0xFF10B981), size: 9.w),
            ),
            SizedBox(height: 2.h),
            Text('Sent!',
                style: TextStyle(
                    fontSize: 20.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 0.5.h),
            Text(
              'Money transferred successfully',
              style: TextStyle(
                  color: const Color(0xFF9CA3AF), fontSize: 12.sp),
            ),
            SizedBox(height: 1.h),
            Text(
              '₦${FormatUtil.formatCurrencyWithComma(state.onlineAmount ?? 0)}',
              style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10B981)),
            ),
            SizedBox(height: 0.5.h),
            Text(
                'TX: ${FormatUtil.formatTransactionId(state.onlineTxId ?? '')}',
                style: TextStyle(
                    fontSize: 11.sp, color: const Color(0xFF9CA3AF))),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done')),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.error_outline, color: Color(0xFFEF4444)),
          SizedBox(width: 8),
          Text('Error'),
        ]),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SendMoneyBloc, SendMoneyState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        switch (state.status) {
          case SendMoneyStatus.onlineSuccess:
            _amountController.clear();
            _showSuccessSheet(context, state);
            context.read<SendMoneyBloc>().add(SendMoneyReset());
          case SendMoneyStatus.offlineQueued:
            _amountController.clear();
            _showOfflineSuccessSheet(context, state);
            context.read<SendMoneyBloc>().add(SendMoneyReset());
          case SendMoneyStatus.error:
            _showError(context, state.errorMessage ?? 'An error occurred');
            context.read<SendMoneyBloc>().add(SendMoneyReset());
          default:
            break;
        }
      },
      builder: (context, state) {
        final isSubmitting = state.status == SendMoneyStatus.submitting;
        return Scaffold(
          appBar: AppBar(title: const Text('Send Money')),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionCard(
                  icon: Icons.qr_code_scanner,
                  title: 'Find Recipient via QR',
                  subtitle: 'Scan the recipient\'s PayMesh QR code',
                  color: const Color(0xFFF0F9FF),
                  borderColor: const Color(0xFFBFDBFE),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _scanQr(context),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan QR Code'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 2.h),

                SectionCard(
                  icon: Icons.broadcast_on_personal,
                  title: 'Be Discoverable via Bluetooth',
                  subtitle: 'Let nearby senders find your device',
                  color: const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFFBBF7D0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.isAdvertising
                              ? 'Broadcasting your ID…'
                              : 'Not broadcasting',
                          style: TextStyle(
                            color: state.isAdvertising
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF6B7280),
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      Switch(
                        value: state.isAdvertising,
                        onChanged: (v) => context
                            .read<SendMoneyBloc>()
                            .add(AdvertisingToggled(v)),
                        activeThumbColor: const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 2.h),

                SectionCard(
                  icon: Icons.person_search,
                  title: 'Find Nearby via Bluetooth',
                  subtitle: 'Scan for PayMesh devices in range',
                  color: const Color(0xFFF9FAFB),
                  borderColor: const Color(0xFFE5E7EB),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: state.isScanning
                              ? null
                              : () => context
                                  .read<SendMoneyBloc>()
                                  .add(BleScanStarted()),
                          icon: state.isScanning
                              ? SizedBox(
                                  width: 4.w,
                                  height: 4.w,
                                  child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Icon(Icons.bluetooth_searching),
                          label: Text(state.isScanning
                              ? 'Scanning…'
                              : 'Scan for Nearby'),
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  vertical: 1.5.h)),
                        ),
                      ),
                      if (state.nearbyDevices.isNotEmpty) ...[
                        SizedBox(height: 1.5.h),
                        Text('Nearby PayMesh Users:',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp)),
                        SizedBox(height: 1.h),
                        ...state.nearbyDevices.map((d) {
                          final isSelected =
                              state.recipientId == d.userId;
                          final initials = d.displayName.length >= 2
                              ? d.displayName
                                  .substring(0, 2)
                                  .toUpperCase()
                              : d.displayName.toUpperCase();
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 5.w,
                              backgroundColor: const Color(0xFF2563EB)
                                  .withValues(alpha: 0.1),
                              child: Text(initials,
                                  style: TextStyle(
                                      color: const Color(0xFF2563EB),
                                      fontSize: 11.sp)),
                            ),
                            title: Text(d.displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text('Signal: ${d.rssi} dBm'),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: Color(0xFF10B981))
                                : TextButton(
                                    onPressed: () => context
                                        .read<SendMoneyBloc>()
                                        .add(
                                            RecipientFromDeviceSelected(d)),
                                    child: const Text('Select'),
                                  ),
                          );
                        }),
                      ] else if (!state.isScanning)
                        Padding(
                          padding: EdgeInsets.only(top: 1.5.h),
                          child: Text(
                            'No PayMesh devices found. Make sure the recipient has "Be Discoverable" turned on.',
                            style: TextStyle(
                                color: const Color(0xFF9CA3AF),
                                fontSize: 11.sp),
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 2.h),

                if (state.recipientId != null) ...[
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF10B981)),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recipient: ${state.recipientName ?? 'Selected'}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                    color: const Color(0xFF065F46)),
                              ),
                              Text(
                                FormatUtil.formatUserId(state.recipientId!),
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color: const Color(0xFF047857)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: const Color(0xFF047857), size: 4.5.w),
                          onPressed: () => context
                              .read<SendMoneyBloc>()
                              .add(RecipientCleared()),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text('Amount',
                      style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937))),
                  SizedBox(height: 1.h),
                  TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '₦ ',
                      prefixStyle: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB)),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              final amount = double.tryParse(
                                  _amountController.text.trim());
                              if (amount == null || amount <= 0) {
                                _showError(
                                    context, 'Enter a valid amount.');
                                return;
                              }
                              context
                                  .read<SendMoneyBloc>()
                                  .add(SendMoneySubmitted(amount));
                            },
                      style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h)),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Send Money',
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 3.5.w,
                          color: const Color(0xFF9CA3AF)),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          'Online: transferred instantly. Offline: saved locally and synced when network returns.',
                          style: TextStyle(
                              fontSize: 10.sp,
                              color: const Color(0xFF9CA3AF)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
