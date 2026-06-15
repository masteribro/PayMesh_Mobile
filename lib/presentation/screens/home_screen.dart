import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../domain/utils/format_util.dart';
import '../controllers/home_controller.dart';
import '../widgets/home/balance_card.dart';
import '../widgets/home/pending_sync_banner.dart';
import '../widgets/home/transaction_list_tile.dart';

enum _MenuOption { topUp, logout }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _controller.loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMyQrSheet() {
    final user = _controller.user;
    if (user == null) return;

    final qrData = jsonEncode({
      'userId': user.userId,
      'username': user.username,
      'type': 'paymesh_id',
    });

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'My QR Code',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Let others scan this to send you money',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              user.username,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
          ],
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
            left: 24,
            right: 24,
            top: 24,
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
                    const Text(
                      'Top Up Balance',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Current balance: ₦${FormatUtil.formatCurrencyWithComma(_controller.user?.balance ?? 0)}',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₦ ',
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
                          onPressed: () => amountController.text =
                              preset.toStringAsFixed(0),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          child: Text('₦${preset.toStringAsFixed(0)}'),
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
                              final amount =
                                  double.parse(amountController.text);
                              await _controller.topUp(amount);
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '₦${FormatUtil.formatCurrencyWithComma(amount)} added to your balance',
                                    ),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              }
                            } catch (e) {
                              setSheetState(() => isLoading = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Top-up failed: $e'),
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                );
                              }
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
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

  Future<void> _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _controller.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    }
  }

  Future<void> _onSync() async {
    try {
      final synced = await _controller.syncTransactions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(synced
              ? 'Transactions synced successfully'
              : 'No pending transactions to sync'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final controller = _controller;
        return Scaffold(
          appBar: AppBar(
            title: const Text('PayMesh Wallet'),
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: controller.isOnline
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      controller.isOnline ? '✓ Online' : '📡 Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              PopupMenuButton<_MenuOption>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (option) {
                  if (option == _MenuOption.topUp) _showTopUpSheet();
                  if (option == _MenuOption.logout) _showLogoutDialog();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _MenuOption.topUp,
                    child: Row(children: [
                      Icon(Icons.add_card, color: Color(0xFF2563EB)),
                      SizedBox(width: 12),
                      Text('Top Up'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: _MenuOption.logout,
                    child: Row(children: [
                      Icon(Icons.logout, color: Color(0xFFEF4444)),
                      SizedBox(width: 12),
                      Text('Logout',
                          style: TextStyle(color: Color(0xFFEF4444))),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: controller.loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        if (controller.error != null)
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFECACA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFDC2626)),
                                const SizedBox(width: 8),
                                Text(
                                  controller.error!,
                                  style: const TextStyle(
                                      color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          ),

                        if (controller.user != null)
                          BalanceCard(user: controller.user!),

                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _showMyQrSheet,
                                  icon: const Icon(Icons.qr_code),
                                  label: const Text('My QR'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      controller.isOnline ? _onSync : null,
                                  icon: const Icon(Icons.sync),
                                  label: const Text('Sync'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        if ((controller.user?.pendingOfflineTransactionCount ??
                                0) >
                            0)
                          PendingSyncBanner(
                            count: controller
                                .user!.pendingOfflineTransactionCount,
                            amount:
                                controller.user!.pendingOfflineAmount,
                          ),

                        const SizedBox(height: 24),

                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Transactions',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text('See All'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (controller.recentTransactions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 64,
                                    color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount:
                                controller.recentTransactions.length,
                            itemBuilder: (context, index) =>
                                TransactionListTile(
                              transaction:
                                  controller.recentTransactions[index],
                              currentUserId:
                                  controller.user?.userId ?? '',
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
