import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/api_client.dart';
import '../../data/services/api_constants.dart';
import '../../data/services/transaction_service.dart';
import '../../domain/services/bluetooth_service.dart';
import '../../domain/services/nfc_service.dart';
import '../../domain/utils/format_util.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen>
    with SingleTickerProviderStateMixin {
  // — services —
  final _authService = AuthService();
  final _apiClient = ApiClient();
  final _txService = TransactionService();
  final _bleService = PayMeshBluetoothService();
  final _nfcService = PayMeshNfcService();

  // — form —
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  // — state —
  bool _isOnline = true;
  bool _isLoading = false;
  StreamSubscription? _connectivitySub;
  late TabController _offlineTabController;

  // — BLE state —
  List<PayMeshDevice> _nearbyDevices = [];
  bool _isScanning = false;
  bool _isAdvertising = false;
  StreamSubscription? _scanSub;

  // — NFC state —
  bool _nfcAvailable = false;
  bool _nfcActive = false;   // NFC session in progress
  String _nfcStatus = '';

  // — selected offline recipient —
  String? _recipientName;

  @override
  void initState() {
    super.initState();
    _offlineTabController = TabController(length: 2, vsync: this);
    _checkConnectivity();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((r) => _onConnectivityChanged(r));
    _initNfc();
  }

  @override
  void dispose() {
    _offlineTabController.dispose();
    _recipientController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _connectivitySub?.cancel();
    _scanSub?.cancel();
    _bleService.stopScan();
    _bleService.stopAdvertising();
    _nfcService.stopSession();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    await _onConnectivityChanged(result);
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> result) async {
    final hasInterface = result.isNotEmpty && !result.contains(ConnectivityResult.none);
    if (!hasInterface) {
      if (mounted) setState(() => _isOnline = false);
      return;
    }
    // Network interface is up — also verify the backend is reachable
    final reachable = await _isBackendReachable();
    if (mounted) setState(() => _isOnline = reachable);
  }

  Future<bool> _isBackendReachable() async {
    try {
      // Any HTTP response (even 401/404) means the server is reachable
      await _apiClient.dio.get(
        ApiConstants.baseUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
          validateStatus: (_) => true, // accept any status code
        ),
      );
      return true;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return false;
      }
      return true; // got a response (e.g. 401) — server is up
    } catch (_) {
      return false;
    }
  }

  Future<void> _initNfc() async {
    final available = await _nfcService.isNfcAvailable();
    if (mounted) setState(() => _nfcAvailable = available);
  }

  // ── ONLINE: send via HTTP ────────────────────────────────────────────────

  Future<void> _sendOnline() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final senderId = await _authService.getUserId();
      if (senderId == null) throw Exception('Not logged in');

      final amount = double.parse(_amountController.text);
      final response = await _apiClient.post(
        '${ApiConstants.baseUrl}/transactions/send',
        data: {
          'senderId': senderId,
          'receiverId': _recipientController.text.trim(),
          'amount': amount,
          'description': _descriptionController.text.trim(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessSheet(data['id'] as String, amount, _recipientController.text.trim());
        _clearForm();
      }
    } on DioException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      // Backend unreachable — switch to offline mode automatically
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        if (mounted) {
          setState(() => _isOnline = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Server unreachable — switched to offline mode. Use Bluetooth or NFC to find the recipient.'),
              backgroundColor: Color(0xFFF59E0B),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) _showError(e.toString());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  // ── OFFLINE: save as PENDING_SYNC ───────────────────────────────────────

  Future<void> _sendOffline() async {
    final recipient = _recipientController.text.trim();
    final amountText = _amountController.text.trim();
    if (recipient.isEmpty) {
      _showError('Select a recipient first (scan BLE or tap via NFC)');
      return;
    }
    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      _showError('Enter a valid amount');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final senderId = await _authService.getUserId();
      if (senderId == null) throw Exception('Not logged in');
      final amount = double.parse(amountText);
      final txId = 'offline_${DateTime.now().millisecondsSinceEpoch}';

      await _txService.createOfflineTransaction(
        id: txId,
        senderId: senderId,
        receiverId: recipient,
        amount: amount,
        timestamp: DateTime.now().toIso8601String(),
        signature: 'sig_${txId.hashCode.abs()}',
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showOfflineSuccessSheet(txId, amount, _recipientName ?? recipient);
        _clearForm();
        setState(() => _recipientName = null);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  // ── BLE ─────────────────────────────────────────────────────────────────

  Future<void> _startBleAdvertise() async {
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

  Future<void> _stopBleAdvertise() async {
    await _bleService.stopAdvertising();
    if (mounted) setState(() => _isAdvertising = false);
  }

  void _startBleScan() {
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

  void _selectBleDevice(PayMeshDevice device) {
    setState(() {
      _recipientController.text = device.userId;
      _recipientName = device.displayName;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recipient set to ${device.displayName}'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  // ── NFC ─────────────────────────────────────────────────────────────────

  Future<void> _nfcShare() async {
    final userId = await _authService.getUserId();
    final cached = await _authService.getCachedAuthResponse();
    if (userId == null || cached == null) return;

    setState(() {
      _nfcActive = true;
      _nfcStatus = 'Hold your phone near the sender\'s phone…';
    });

    await _nfcService.writeUserId(
      userId: userId,
      username: cached.username,
      onSuccess: () {
        if (mounted) {
          setState(() {
            _nfcActive = false;
            _nfcStatus = 'Your ID was shared successfully!';
          });
        }
      },
      onError: (msg) {
        if (mounted) setState(() { _nfcActive = false; _nfcStatus = 'Error: $msg'; });
      },
    );
  }

  Future<void> _nfcScan() async {
    setState(() {
      _nfcActive = true;
      _nfcStatus = 'Hold your phone near the recipient\'s phone…';
    });

    await _nfcService.readRecipientId(
      onRecipientFound: (r) {
        if (mounted) {
          setState(() {
            _recipientController.text = r.userId;
            _recipientName = r.username;
            _nfcActive = false;
            _nfcStatus = 'Got recipient: ${r.username}';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recipient set to ${r.username}'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      },
      onError: (msg) {
        if (mounted) setState(() { _nfcActive = false; _nfcStatus = 'Error: $msg'; });
      },
    );
  }

  void _cancelNfc() {
    _nfcService.stopSession();
    if (mounted) setState(() { _nfcActive = false; _nfcStatus = ''; });
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  void _clearForm() {
    _recipientController.clear();
    _amountController.clear();
    _descriptionController.clear();
    setState(() {});
  }

  void _showError(String message) {
    String clean = message;
    final match = RegExp(r'"message":"([^"]+)"').firstMatch(message);
    if (match != null) clean = match.group(1)!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.error_outline, color: Color(0xFFEF4444)),
          SizedBox(width: 8),
          Text('Failed'),
        ]),
        content: Text(clean),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _showSuccessSheet(String txId, double amount, String recipient) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SuccessSheet(txId: txId, amount: amount, recipient: recipient, isOffline: false),
    );
  }

  void _showOfflineSuccessSheet(String txId, double amount, String recipientName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SuccessSheet(txId: txId, amount: amount, recipient: recipientName, isOffline: true),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Container(
            color: _isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _isOnline ? 'Online — using internet' : 'Offline — using Bluetooth / NFC',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isOnline ? _buildOnlineForm() : _buildOfflineForm(),
    );
  }

  // ── ONLINE FORM ──────────────────────────────────────────────────────────

  Widget _buildOnlineForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recipient ID',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            TextFormField(
              controller: _recipientController,
              decoration: const InputDecoration(
                hintText: 'Paste recipient user ID',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter recipient ID' : null,
            ),
            const SizedBox(height: 20),
            const Text('Amount',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixText: '\$ ',
                prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter amount';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter valid amount';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text('Description (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(hintText: 'Add a note'),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(color: Color(0xFF4B5563))),
                  Text(
                    _amountController.text.isEmpty
                        ? '\$0.00'
                        : '\$${FormatUtil.formatCurrencyWithComma(double.tryParse(_amountController.text) ?? 0)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSendButton('Send Money', _isLoading ? null : _sendOnline),
          ],
        ),
      ),
    );
  }

  // ── OFFLINE FORM ─────────────────────────────────────────────────────────

  Widget _buildOfflineForm() {
    return Column(
      children: [
        // Recipient display if one is selected
        if (_recipientController.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recipient: ${_recipientName ?? 'Selected'}',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF065F46))),
                      Text(FormatUtil.formatUserId(_recipientController.text),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF047857))),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF047857), size: 18),
                  onPressed: () => setState(() {
                    _recipientController.clear();
                    _recipientName = null;
                  }),
                ),
              ],
            ),
          ),

        // Amount + Send (shown when recipient is selected)
        if (_recipientController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Amount',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    prefixText: '\$ ',
                    prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                _buildSendButton('Save Offline Transaction', _isLoading ? null : _sendOffline),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Color(0xFF9CA3AF)),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Saved locally — will sync with server when you\'re back online',
                        style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Tabs: Bluetooth | NFC
        TabBar(
          controller: _offlineTabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: const Color(0xFF2563EB),
          tabs: const [
            Tab(icon: Icon(Icons.bluetooth), text: 'Bluetooth'),
            Tab(icon: Icon(Icons.nfc), text: 'NFC'),
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: _offlineTabController,
            children: [
              _buildBluetoothTab(),
              _buildNfcTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ── BLUETOOTH TAB ────────────────────────────────────────────────────────

  Widget _buildBluetoothTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Be discoverable section
          _SectionCard(
            icon: Icons.broadcast_on_personal,
            title: 'Be Discoverable (Receiver)',
            subtitle: 'Start advertising so nearby senders can find you',
            color: const Color(0xFFF0F9FF),
            borderColor: const Color(0xFFBFDBFE),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isAdvertising ? 'Broadcasting your ID…' : 'Not broadcasting',
                    style: TextStyle(
                      color: _isAdvertising ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ),
                Switch(
                  value: _isAdvertising,
                  onChanged: (v) => v ? _startBleAdvertise() : _stopBleAdvertise(),
                  activeColor: const Color(0xFF2563EB),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Scan section
          _SectionCard(
            icon: Icons.person_search,
            title: 'Find Nearby Users (Sender)',
            subtitle: 'Scan for nearby PayMesh devices',
            color: const Color(0xFFF9FAFB),
            borderColor: const Color(0xFFE5E7EB),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _startBleScan,
                    icon: _isScanning
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search),
                    label: Text(_isScanning ? 'Scanning…' : 'Scan for Nearby'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                if (_nearbyDevices.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Nearby PayMesh Users:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...List.generate(_nearbyDevices.length, (i) {
                    final d = _nearbyDevices[i];
                    final isSelected = _recipientController.text == d.userId;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        child: Text(d.displayName.substring(3, min(d.displayName.length, 5)),
                            style: const TextStyle(color: Color(0xFF2563EB), fontSize: 12)),
                      ),
                      title: Text(d.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Signal: ${d.rssi} dBm'),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                          : TextButton(
                              onPressed: () => _selectBleDevice(d),
                              child: const Text('Select'),
                            ),
                    );
                  }),
                ] else if (!_isScanning)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('No PayMesh devices found yet. Make sure the recipient has "Be Discoverable" turned on.',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── NFC TAB ──────────────────────────────────────────────────────────────

  Widget _buildNfcTab() {
    if (!_nfcAvailable) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nfc, size: 64, color: Color(0xFFD1D5DB)),
            SizedBox(height: 12),
            Text('NFC is not available on this device',
                style: TextStyle(color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Share your ID (Receiver)
          _SectionCard(
            icon: Icons.share,
            title: 'Share My ID (Receiver)',
            subtitle: 'Hold your phone near the sender\'s phone to share your user ID',
            color: const Color(0xFFF0F9FF),
            borderColor: const Color(0xFFBFDBFE),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_nfcActive && _nfcStatus.contains('sender'))
                  _buildNfcActiveIndicator(_nfcStatus),
                if (_nfcStatus.isNotEmpty && !_nfcActive)
                  Text(_nfcStatus,
                      style: TextStyle(
                        color: _nfcStatus.startsWith('Error')
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        fontSize: 13,
                      )),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _nfcActive ? _cancelNfc : _nfcShare,
                    icon: Icon(_nfcActive ? Icons.stop : Icons.nfc),
                    label: Text(_nfcActive ? 'Cancel' : 'Share My ID via NFC'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Read recipient ID (Sender)
          _SectionCard(
            icon: Icons.contactless,
            title: 'Get Recipient ID (Sender)',
            subtitle: 'Tap your phone on the recipient\'s phone to get their ID',
            color: const Color(0xFFF9FAFB),
            borderColor: const Color(0xFFE5E7EB),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_nfcActive && _nfcStatus.contains('recipient'))
                  _buildNfcActiveIndicator(_nfcStatus),
                if (_nfcStatus.isNotEmpty && !_nfcActive)
                  Text(_nfcStatus,
                      style: TextStyle(
                        color: _nfcStatus.startsWith('Error')
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        fontSize: 13,
                      )),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _nfcActive ? _cancelNfc : _nfcScan,
                    icon: Icon(_nfcActive ? Icons.stop : Icons.nfc),
                    label: Text(_nfcActive ? 'Cancel' : 'Scan Recipient via NFC'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNfcActiveIndicator(String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(status, style: const TextStyle(fontSize: 13, color: Color(0xFF2563EB)))),
        ],
      ),
    );
  }

  Widget _buildSendButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Reusable section card ────────────────────────────────────────────────────

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
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Success bottom sheet ──────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  final String txId;
  final double amount;
  final String recipient;
  final bool isOffline;

  const _SuccessSheet({
    required this.txId,
    required this.amount,
    required this.recipient,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: isOffline ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOffline ? Icons.schedule_send : Icons.check,
              color: isOffline ? const Color(0xFFD97706) : const Color(0xFF10B981),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isOffline ? 'Saved for Later!' : 'Money Sent!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (isOffline)
            const Text('Will sync when you\'re back online',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '\$${FormatUtil.formatCurrencyWithComma(amount)}',
            style: TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold,
              color: isOffline ? const Color(0xFFD97706) : const Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 8),
          Text('To: $recipient', style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Text('TX: ${FormatUtil.formatTransactionId(txId)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}