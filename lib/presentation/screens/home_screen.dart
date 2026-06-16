import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../domain/utils/format_util.dart';
import '../blocs/home/home_bloc.dart';
import '../widgets/home/balance_card.dart';
import '../widgets/home/pending_sync_banner.dart';
import '../widgets/home/transaction_list_tile.dart';
import 'scan_incoming_payment_screen.dart';

enum _MenuOption { topUp, logout }

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  void _showMyQrSheet(BuildContext context, HomeState state) {
    final user = state.user;
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

  void _showTopUpSheet(BuildContext context, HomeState state) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Current balance: ₦${FormatUtil.formatCurrencyWithComma(state.user?.balance ?? 0)}',
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
                        onPressed: () =>
                            amountController.text = preset.toStringAsFixed(0),
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
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final amount = double.parse(amountController.text);
                    context.read<HomeBloc>().add(HomeTopUpRequested(amount));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '₦${FormatUtil.formatCurrencyWithComma(amount)} added to your balance',
                        ),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  },
                  child: const Text('Add Money'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
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
    if (confirm == true && context.mounted) {
      context.read<HomeBloc>().add(HomeLogoutRequested());
    }
  }

  Future<void> _scanIncomingPayment(BuildContext context) async {
    final received = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ScanIncomingPaymentScreen()),
    );
    if (received == true && context.mounted) {
      context.read<HomeBloc>().add(HomeLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (prev, curr) =>
          prev.loggedOut != curr.loggedOut ||
          prev.syncStatus != curr.syncStatus,
      listener: (context, state) {
        if (state.loggedOut) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
          return;
        }
        switch (state.syncStatus) {
          case HomeSyncStatus.success:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Transactions synced successfully')),
            );
          case HomeSyncStatus.nothingToSync:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('No pending transactions to sync')),
            );
          case HomeSyncStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sync failed: ${state.syncError ?? ''}'),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          default:
            break;
        }
      },
      builder: (context, state) {
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
                      color: state.isOnline
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      state.isOnline ? '✓ Online' : '📡 Offline',
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
                  if (option == _MenuOption.topUp) {
                    _showTopUpSheet(context, state);
                  }
                  if (option == _MenuOption.logout) {
                    _showLogoutDialog(context);
                  }
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
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async =>
                      context.read<HomeBloc>().add(HomeLoadRequested()),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        if (state.error != null)
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
                                  state.error!,
                                  style: const TextStyle(
                                      color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                          ),

                        if (state.user != null)
                          BalanceCard(user: state.user!),

                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _showMyQrSheet(context, state),
                                      icon: const Icon(Icons.qr_code),
                                      label: const Text('My QR'),
                                      style: ElevatedButton.styleFrom(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: state.isOnline
                                          ? () => context
                                              .read<HomeBloc>()
                                              .add(HomeSyncRequested())
                                          : null,
                                      icon: state.syncStatus ==
                                              HomeSyncStatus.syncing
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                      strokeWidth: 2),
                                            )
                                          : const Icon(Icons.sync),
                                      label: const Text('Sync'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _scanIncomingPayment(context),
                                  icon: const Icon(Icons.qr_code_scanner),
                                  label: const Text('Scan Payment QR'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        if ((state.user?.pendingOfflineTransactionCount ??
                                0) >
                            0)
                          PendingSyncBanner(
                            count: state
                                .user!.pendingOfflineTransactionCount,
                            amount:
                                state.user!.pendingOfflineAmount,
                          ),

                        if (state.incomingPendingAmount > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF6EE7B7)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_downward,
                                    color: Color(0xFF10B981)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Incoming (Pending)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF065F46),
                                        ),
                                      ),
                                      Text(
                                        '₦${FormatUtil.formatCurrency(state.incomingPendingAmount)} — sync to confirm',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF047857),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

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

                        if (state.recentTransactions.isEmpty)
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
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount:
                                state.recentTransactions.length,
                            itemBuilder: (context, index) =>
                                TransactionListTile(
                              transaction:
                                  state.recentTransactions[index],
                              currentUserId:
                                  state.user?.userId ?? '',
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
