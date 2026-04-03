import 'package:flutter/material.dart';
import '../../data/dto/auth_response.dart';
import '../../data/dto/offline_transaction_request.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/api_client.dart';
import '../../data/services/api_constants.dart';
import '../../data/services/transaction_service.dart';
import '../../domain/utils/format_util.dart';

enum _MenuOption { topUp, logout }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _transactionService = TransactionService();
  final _apiClient = ApiClient();

  AuthResponse? _user;
  List<TransactionModel> _recentTransactions = [];
  bool _isLoading = true;
  bool _isOnline = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load cached user first so screen isn't empty
      final cached = await _authService.getCachedAuthResponse();
      if (cached != null && mounted) {
        setState(() => _user = cached);
      }

      final userId = await _authService.getUserId();
      if (userId == null) return;

      // Fetch fresh user profile from backend
      try {
        final response = await _apiClient.get('${ApiConstants.baseUrl}/users/$userId');
        final data = response.data as Map<String, dynamic>;

        final updatedUser = AuthResponse(
          token: cached?.token ?? '',
          userId: userId,
          username: data['username'] ?? cached?.username ?? '',
          email: data['email'] ?? cached?.email ?? '',
          balance: (data['balance'] as num).toDouble(),
          pendingOfflineAmount: (data['pendingOfflineAmount'] as num).toDouble(),
          pendingOfflineTransactionCount: data['pendingOfflineTransactionCount'] as int,
        );

        if (mounted) setState(() => _user = updatedUser);
        _isOnline = true;
      } catch (_) {
        _isOnline = false;
      }

      // Load pending offline transactions from local storage
      final pending = await _transactionService.getPendingTransactions();
      if (mounted) {
        setState(() {
          _recentTransactions = pending.take(5).map(_toTransactionModel).toList();
          _isLoading = false;
          _isOnline = _isOnline;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data';
          _isLoading = false;
        });
      }
    }
  }

  TransactionModel _toTransactionModel(OfflineTransactionRequest r) {
    return TransactionModel(
      id: r.id,
      senderId: r.senderId,
      receiverId: r.receiverId,
      amount: r.amount,
      timestamp: DateTime.tryParse(r.timestamp) ?? DateTime.now(),
      signature: r.signature,
      status: 'PENDING_SYNC',
      createdAt: DateTime.tryParse(r.timestamp) ?? DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayMesh Wallet'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isOnline ? '✓ Online' : '📡 Offline',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          PopupMenuButton<_MenuOption>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (option) {
              if (option == _MenuOption.topUp) _showTopUpSheet();
              if (option == _MenuOption.logout) _logout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _MenuOption.topUp,
                child: Row(
                  children: [
                    Icon(Icons.add_card, color: Color(0xFF2563EB)),
                    SizedBox(width: 12),
                    Text('Top Up'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _MenuOption.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFFEF4444)),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Color(0xFFEF4444))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFECACA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))),
                          ],
                        ),
                      ),

                    // Balance Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${_user?.username ?? ''}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Total Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${FormatUtil.formatCurrencyWithComma(_user?.balance ?? 0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Available',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${FormatUtil.formatCurrency((_user?.balance ?? 0) - (_user?.pendingOfflineAmount ?? 0))}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pending',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${FormatUtil.formatCurrency(_user?.pendingOfflineAmount ?? 0)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Request Money feature coming soon')),
                                );
                              },
                              icon: const Icon(Icons.arrow_downward),
                              label: const Text('Request'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isOnline ? _syncTransactions : null,
                              icon: const Icon(Icons.sync),
                              label: const Text('Sync'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pending Transactions Alert
                    if ((_user?.pendingOfflineTransactionCount ?? 0) > 0)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCD34D), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: Color(0xFFD97706)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pending Sync',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                  Text(
                                    '${_user!.pendingOfflineTransactionCount} transactions waiting to sync (\$${FormatUtil.formatCurrency(_user!.pendingOfflineAmount)})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Recent Transactions Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pending Transactions',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (_recentTransactions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'No pending transactions',
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _recentTransactions[index];
                          final isSent = transaction.senderId == _user?.userId;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Card(
                              child: ListTile(
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isSent
                                        ? const Color(0xFFEF4444).withOpacity(0.1)
                                        : const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isSent ? Icons.arrow_upward : Icons.arrow_downward,
                                      color: isSent ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  isSent
                                      ? 'Sent to ${FormatUtil.formatUserId(transaction.receiverId)}'
                                      : 'Received from ${FormatUtil.formatUserId(transaction.senderId)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  FormatUtil.formatDateTime(transaction.timestamp),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isSent ? '-' : '+'}\$${FormatUtil.formatCurrency(transaction.amount)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSent ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: transaction.status == 'PENDING_SYNC'
                                            ? const Color(0xFFFCD34D).withOpacity(0.3)
                                            : const Color(0xFFD1FAE5).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        transaction.status == 'PENDING_SYNC' ? 'Pending' : 'Synced',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: transaction.status == 'PENDING_SYNC'
                                              ? const Color(0xFFB45309)
                                              : const Color(0xFF047857),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  void _showTopUpSheet() {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Top Up Balance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Current balance: \$${FormatUtil.formatCurrencyWithComma(_user?.balance ?? 0)}',
                    style: const TextStyle(color: Color(0xFF6B7280))),
                const SizedBox(height: 20),
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$ ',
                    hintText: '0.00',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter an amount';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (final preset in [100.0, 500.0, 1000.0])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: () => amountController.text = preset.toStringAsFixed(0),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text('\$${preset.toStringAsFixed(0)}'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() => isLoading = true);
                            try {
                              final userId = await _authService.getUserId();
                              final amount = double.parse(amountController.text);
                              await _apiClient.post(
                                '${ApiConstants.baseUrl}/users/$userId/topup',
                                data: {'amount': amount},
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('\$${FormatUtil.formatCurrencyWithComma(amount)} added to your balance'),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                                _loadData();
                              }
                            } catch (e) {
                              setSheetState(() => isLoading = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Top-up failed: $e'), backgroundColor: const Color(0xFFEF4444)),
                                );
                              }
                            }
                          },
                    child: isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Add Money'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    }
  }

  Future<void> _syncTransactions() async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    final pending = await _transactionService.getPendingTransactions();
    if (pending.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pending transactions to sync')),
        );
      }
      return;
    }

    try {
      await _transactionService.syncTransactions(userId: userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transactions synced successfully')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }
}