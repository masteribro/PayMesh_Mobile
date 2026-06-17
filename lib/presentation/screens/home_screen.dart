import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
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
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'My QR Code',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Let others scan this to send you money',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 3.h),
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 55.w,
              backgroundColor: Colors.white,
            ),
            SizedBox(height: 2.h),
            Text(
              user.username,
              style:
                  TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 0.5.h),
            Text(
              user.email,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
            ),
            SizedBox(height: 3.h),
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
          left: 6.w,
          right: 6.w,
          top: 3.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 3.h,
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
                  Text(
                    'Top Up Balance',
                    style: TextStyle(
                        fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                'Current balance: ₦${FormatUtil.formatCurrencyWithComma(state.user?.balance ?? 0)}',
                style: TextStyle(
                    fontSize: 13.sp, color: const Color(0xFF6B7280)),
              ),
              SizedBox(height: 2.5.h),
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
              SizedBox(height: 2.h),
              Row(
                children: [
                  for (final preset in [100.0, 500.0, 1000.0])
                    Padding(
                      padding: EdgeInsets.only(right: 2.w),
                      child: OutlinedButton(
                        onPressed: () => amountController.text =
                            preset.toStringAsFixed(0),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 4.w, vertical: 1.h),
                        ),
                        child: Text('₦${preset.toStringAsFixed(0)}'),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 2.5.h),
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
            child: const Text('Logout',
                style: TextStyle(color: Color(0xFFEF4444))),
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
                padding: EdgeInsets.only(left: 2.w),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 2.5.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: state.isOnline
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      state.isOnline ? '✓ Online' : '📡 Offline',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
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
                            margin: EdgeInsets.all(4.w),
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFECACA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFDC2626)),
                                SizedBox(width: 2.w),
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
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
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
                                        padding: EdgeInsets.symmetric(
                                            vertical: 1.5.h),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 3.w),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: state.isOnline
                                          ? () => context
                                              .read<HomeBloc>()
                                              .add(HomeSyncRequested())
                                          : null,
                                      icon: state.syncStatus ==
                                              HomeSyncStatus.syncing
                                          ? SizedBox(
                                              width: 4.w,
                                              height: 4.w,
                                              child:
                                                  const CircularProgressIndicator(
                                                      strokeWidth: 2),
                                            )
                                          : const Icon(Icons.sync),
                                      label: const Text('Sync'),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 1.5.h),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _scanIncomingPayment(context),
                                  icon: const Icon(Icons.qr_code_scanner),
                                  label: const Text('Scan Payment QR'),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 1.5.h),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 3.h),

                        if ((state.user?.pendingOfflineTransactionCount ??
                                0) >
                            0)
                          PendingSyncBanner(
                            count: state
                                .user!.pendingOfflineTransactionCount,
                            amount: state.user!.pendingOfflineAmount,
                          ),

                        if (state.incomingPendingAmount > 0) ...[
                          SizedBox(height: 1.h),
                          Container(
                            margin:
                                EdgeInsets.symmetric(horizontal: 4.w),
                            padding: EdgeInsets.all(3.w),
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
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Incoming (Pending)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.sp,
                                          color: const Color(0xFF065F46),
                                        ),
                                      ),
                                      Text(
                                        '₦${FormatUtil.formatCurrency(state.incomingPendingAmount)} — sync to confirm',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: const Color(0xFF047857),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        SizedBox(height: 3.h),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent Transactions',
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text('See All'),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 1.5.h),

                        if (state.recentTransactions.isEmpty)
                          Padding(
                            padding: EdgeInsets.all(8.w),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 16.w,
                                    color: Colors.grey[300]),
                                SizedBox(height: 1.5.h),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 13.sp),
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

                        SizedBox(height: 3.h),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
