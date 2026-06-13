import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/transaction_service.dart';
import '../../domain/services/bluetooth_service.dart';
import '../../domain/utils/format_util.dart';
import 'qr_scanner_screen.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _authService = AuthService();
  final _txService = TransactionService();
  final _bleService = PayMeshBluetoothService();

  final _amountController = TextEditingController();

  bool _isLoading = false;
  bool _isAdvertising = false;
  bool _isScanning = false;
  List<PayMeshDevice> _nearbyDevices = [];
  StreamSubscription? _scanSub;

  String? _recipientId;
  String? _recipientName;

  @override
  void dispose() {
    _amountController.dispose();
    _scanSub?.cancel();
    _bleService.stopScan();
    _bleService.stopAdvertising();
    super.dispose();
  }

  // ── QR Code ───────────────────────────────────────────────────────────────

  Future<void> _scanQr() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result == null || !mounted) return;
    setState(() {
      _recipientId = result['userId'] as String?;
      _recipientName = result['username'] as String?;
    });
    if (_recipientId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipient set to ${_recipientName ?? _recipientId}'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  // ── BLE ───────────────────────────────────────────────────────────────────

  Future<void> _startAdvertise() async {
    final userId = await _authService.getUserId();
    final cached = await _authService.getCachedAuthResponse();
    if (userId == null || cached == null) return;
    try {
      await _bleService.startAdvertising(userId: userId, username: cached.username);
      if (mounted) setState(() => _isAdvertising = true);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('permissions denied')) {
        _showError('Bluetooth permission denied.\n\nGo to Settings → Apps → PayMesh → Permissions and enable Bluetooth.');
      } else {
        _showError('Could not start advertising: $msg');
      }
    }
  }

  Future<void> _stopAdvertise() async {
    await _bleService.stopAdvertising();
    if (mounted) setState(() => _isAdvertising = false);
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _nearbyDevices = [];
    });
    _scanSub?.cancel();
    _scanSub = _bleService.scanForDevices().listen(
      (devices) {
        if (mounted) setState(() => _nearbyDevices = devices);
      },
      onDone: () {
        if (mounted) setState(() => _isScanning = false);
      },
    );
  }

  void _selectDevice(PayMeshDevice device) {
    setState(() {
      _recipientId = device.userId;
      _recipientName = device.displayName;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recipient set to ${device.displayName}'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  // ── Send ─────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    if (_recipientId == null) {
      _showError('Scan the recipient\'s QR code first.');
      return;
    }
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Enter a valid amount.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final senderId = await _authService.getUserId();
      if (senderId == null) throw Exception('Not logged in');

      final result = await _txService.sendMoneyOnline(
        senderId: senderId,
        receiverId: _recipientId!,
        amount: amount,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessSheet(result.id, amount, _recipientName ?? _recipientId!);
        _amountController.clear();
        setState(() {
          _recipientId = null;
          _recipientName = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showError(String message) {
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  void _showSuccessSheet(String txId, double amount, String recipientName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle,
                  color: Color(0xFF10B981), size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Sent!',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Money transferred successfully",
                style:
                    TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
            const SizedBox(height: 8),
            Text(
              '\$${FormatUtil.formatCurrencyWithComma(amount)}',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 8),
            Text('To: $recipientName',
                style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 4),
            Text('TX: ${FormatUtil.formatTransactionId(txId)}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 24),
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Money')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Scan QR to find recipient ─────────────────────────────────
            _SectionCard(
              icon: Icons.qr_code_scanner,
              title: 'Find Recipient via QR',
              subtitle: 'Scan the recipient\'s PayMesh QR code',
              color: const Color(0xFFF0F9FF),
              borderColor: const Color(0xFFBFDBFE),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _scanQr,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR Code'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Be Discoverable (BLE) ─────────────────────────────────────
            _SectionCard(
              icon: Icons.broadcast_on_personal,
              title: 'Be Discoverable via Bluetooth',
              subtitle: 'Let nearby senders find your device',
              color: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFFBBF7D0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isAdvertising
                          ? 'Broadcasting your ID…'
                          : 'Not broadcasting',
                      style: TextStyle(
                        color: _isAdvertising
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isAdvertising,
                    onChanged: (v) => v ? _startAdvertise() : _stopAdvertise(),
                    activeThumbColor: const Color(0xFF16A34A),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Scan for Nearby (BLE) ─────────────────────────────────────
            _SectionCard(
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
                      onPressed: _isScanning ? null : _startScan,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.bluetooth_searching),
                      label: Text(_isScanning ? 'Scanning…' : 'Scan for Nearby'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  if (_nearbyDevices.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Nearby PayMesh Users:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...List.generate(_nearbyDevices.length, (i) {
                      final d = _nearbyDevices[i];
                      final isSelected = _recipientId == d.userId;
                      final initials = d.displayName.length >= 2
                          ? d.displayName.substring(0, 2).toUpperCase()
                          : d.displayName.toUpperCase();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF2563EB).withValues(alpha: 0.1),
                          child: Text(initials,
                              style: const TextStyle(
                                  color: Color(0xFF2563EB), fontSize: 12)),
                        ),
                        title: Text(d.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Signal: ${d.rssi} dBm'),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: Color(0xFF10B981))
                            : TextButton(
                                onPressed: () => _selectDevice(d),
                                child: const Text('Select'),
                              ),
                      );
                    }),
                  ] else if (!_isScanning)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'No PayMesh devices found. Make sure the recipient has "Be Discoverable" turned on.',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Send Form (visible after recipient is selected) ───────────
            if (_recipientId != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recipient: ${_recipientName ?? 'Selected'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF065F46)),
                          ),
                          Text(
                            FormatUtil.formatUserId(_recipientId!),
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Color(0xFF047857), size: 18),
                      onPressed: () => setState(() {
                        _recipientId = null;
                        _recipientName = null;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Amount',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937))),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB)),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _send,
                  style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Send Money',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Color(0xFF9CA3AF)),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "Transferred instantly — balance updated on both accounts",
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Reusable section card ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color borderColor;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB), size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
