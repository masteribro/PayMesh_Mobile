import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/utils/format_util.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final String userId = 'user123';
  late List<TransactionModel> allTransactions;
  String _filterStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    allTransactions = [
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
      TransactionModel(
        id: 'txn004',
        senderId: 'user111',
        receiverId: 'user123',
        amount: 200.00,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        signature: 'sig000',
        status: 'COMPLETED',
        syncedAt: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      TransactionModel(
        id: 'txn005',
        senderId: 'user123',
        receiverId: 'user222',
        amount: 30.00,
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        signature: 'sig111',
        status: 'COMPLETED',
        syncedAt: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  List<TransactionModel> get filteredTransactions {
    if (_filterStatus == 'ALL') {
      return allTransactions;
    } else if (_filterStatus == 'SENT') {
      return allTransactions.where((t) => t.senderId == userId).toList();
    } else if (_filterStatus == 'RECEIVED') {
      return allTransactions.where((t) => t.receiverId == userId).toList();
    } else if (_filterStatus == 'PENDING') {
      return allTransactions.where((t) => t.isPendingSync).toList();
    }
    return allTransactions;
  }

  String _getTransactionTitle(TransactionModel transaction) {
    final isSent = transaction.senderId == userId;
    if (isSent) {
      return 'Sent to ${FormatUtil.formatUserId(transaction.receiverId)}';
    } else {
      return 'Received from ${FormatUtil.formatUserId(transaction.senderId)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterStatus == 'ALL',
                  onSelected: (selected) {
                    setState(() {
                      _filterStatus = 'ALL';
                    });
                  },
                  backgroundColor: Colors.transparent,
                  side: BorderSide(
                    color: _filterStatus == 'ALL' ? const Color(0xFF2563EB) : Colors.grey[300]!,
                    width: 2,
                  ),
                  labelStyle: TextStyle(
                    color: _filterStatus == 'ALL' ? const Color(0xFF2563EB) : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Sent'),
                  selected: _filterStatus == 'SENT',
                  onSelected: (selected) {
                    setState(() {
                      _filterStatus = 'SENT';
                    });
                  },
                  backgroundColor: Colors.transparent,
                  side: BorderSide(
                    color: _filterStatus == 'SENT' ? const Color(0xFF2563EB) : Colors.grey[300]!,
                    width: 2,
                  ),
                  labelStyle: TextStyle(
                    color: _filterStatus == 'SENT' ? const Color(0xFF2563EB) : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Received'),
                  selected: _filterStatus == 'RECEIVED',
                  onSelected: (selected) {
                    setState(() {
                      _filterStatus = 'RECEIVED';
                    });
                  },
                  backgroundColor: Colors.transparent,
                  side: BorderSide(
                    color: _filterStatus == 'RECEIVED' ? const Color(0xFF2563EB) : Colors.grey[300]!,
                    width: 2,
                  ),
                  labelStyle: TextStyle(
                    color: _filterStatus == 'RECEIVED' ? const Color(0xFF2563EB) : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pending'),
                  selected: _filterStatus == 'PENDING',
                  onSelected: (selected) {
                    setState(() {
                      _filterStatus = 'PENDING';
                    });
                  },
                  backgroundColor: Colors.transparent,
                  side: BorderSide(
                    color: _filterStatus == 'PENDING' ? const Color(0xFF2563EB) : Colors.grey[300]!,
                    width: 2,
                  ),
                  labelStyle: TextStyle(
                    color: _filterStatus == 'PENDING' ? const Color(0xFF2563EB) : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start by sending or receiving money',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      final isSent = transaction.senderId == userId;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              _showTransactionDetails(context, transaction);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
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
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getTransactionTitle(transaction),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          FormatUtil.formatDateTime(transaction.timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: transaction.status == 'PENDING_SYNC'
                                                ? const Color(0xFFFCD34D).withOpacity(0.3)
                                                : transaction.status == 'COMPLETED'
                                                    ? const Color(0xFFD1FAE5).withOpacity(0.5)
                                                    : const Color(0xFFFECACA).withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            transaction.status == 'PENDING_SYNC'
                                                ? 'Pending Sync'
                                                : transaction.status == 'COMPLETED'
                                                    ? 'Completed'
                                                    : transaction.status,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: transaction.status == 'PENDING_SYNC'
                                                  ? const Color(0xFFB45309)
                                                  : transaction.status == 'COMPLETED'
                                                      ? const Color(0xFF047857)
                                                      : const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${isSent ? '-' : '+'}\$${FormatUtil.formatCurrency(transaction.amount)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isSent ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey[400],
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, TransactionModel transaction) {
    final isSent = transaction.senderId == userId;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${isSent ? '-' : '+'}\$${FormatUtil.formatCurrency(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isSent ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Transaction ID', FormatUtil.formatTransactionId(transaction.id)),
            _buildDetailRow(
              isSent ? 'Recipient' : 'Sender',
              FormatUtil.formatUserId(isSent ? transaction.receiverId : transaction.senderId),
            ),
            _buildDetailRow('Amount', '\$${FormatUtil.formatCurrency(transaction.amount)}'),
            _buildDetailRow('Date', FormatUtil.formatDateTime(transaction.timestamp)),
            _buildDetailRow('Status', transaction.status.replaceAll('_', ' ')),
            if (transaction.syncedAt != null)
              _buildDetailRow('Synced At', FormatUtil.formatDateTime(transaction.syncedAt!)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
