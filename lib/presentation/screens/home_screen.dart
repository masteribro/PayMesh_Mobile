import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/utils/format_util.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mock data - replace with actual data from repositories
  late UserModel user;
  late List<TransactionModel> recentTransactions;
  bool isOffline = true;

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    user = UserModel(
      userId: 'user123',
      email: 'john.doe@example.com',
      username: 'johndoe',
      balance: 2500.50,
      pendingOfflineAmount: 250.00,
      pendingOfflineTransactionCount: 3,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );

    recentTransactions = [
      TransactionModel(
        id: 'txn001',
        senderId: 'user123',
        receiverId: 'user456',
        amount: 50.00,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        signature: 'sig123',
        status: 'PENDING_SYNC',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      TransactionModel(
        id: 'txn002',
        senderId: 'user789',
        receiverId: 'user123',
        amount: 100.00,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        signature: 'sig456',
        status: 'COMPLETED',
        syncedAt: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: 'txn003',
        senderId: 'user123',
        receiverId: 'user999',
        amount: 75.50,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        signature: 'sig789',
        status: 'COMPLETED',
        syncedAt: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayMesh Wallet'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOffline ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOffline ? '📡 Offline' : '✓ Online',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                  const Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${FormatUtil.formatCurrencyWithComma(user.balance)}',
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
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${FormatUtil.formatCurrency(user.availableBalance)}',
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
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${FormatUtil.formatCurrency(user.pendingOfflineAmount)}',
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sync feature coming soon')),
                        );
                      },
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pending Transactions Alert
            if (user.pendingOfflineTransactionCount > 0)
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
                            '${user.pendingOfflineTransactionCount} transactions waiting to sync (\$${FormatUtil.formatCurrency(user.pendingOfflineAmount)})',
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
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Transactions List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentTransactions.length,
              itemBuilder: (context, index) {
                final transaction = recentTransactions[index];
                final isSent = transaction.senderId == user.userId;

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
                        isSent ? 'Sent to ${FormatUtil.formatUserId(transaction.receiverId)}' : 'Received from ${FormatUtil.formatUserId(transaction.senderId)}',
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
    );
  }
}
