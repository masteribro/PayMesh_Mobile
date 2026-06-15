import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/utils/format_util.dart';
import '../controllers/transaction_history_controller.dart';
import '../widgets/transaction_history/history_transaction_tile.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late final TransactionHistoryController _controller;
  String _filterStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _controller = TransactionHistoryController();
    _controller.loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<TransactionModel> get _filtered {
    final all = _controller.transactions;
    final userId = _controller.userId;
    switch (_filterStatus) {
      case 'SENT':
        return all.where((t) => t.senderId == userId).toList();
      case 'RECEIVED':
        return all.where((t) => t.receiverId == userId).toList();
      case 'PENDING':
        return all.where((t) => t.isPendingSync).toList();
      default:
        return all;
    }
  }

  void _showTransactionDetails(TransactionModel tx) {
    final isSent = tx.senderId == _controller.userId;

    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  '${isSent ? '-' : '+'}₦${FormatUtil.formatCurrency(tx.amount)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isSent
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _DetailRow(
                label: 'Transaction ID',
                value: FormatUtil.formatTransactionId(tx.id)),
            _DetailRow(
              label: isSent ? 'Recipient' : 'Sender',
              value: FormatUtil.formatUserId(
                  isSent ? tx.receiverId : tx.senderId),
            ),
            _DetailRow(
                label: 'Amount',
                value: '₦${FormatUtil.formatCurrency(tx.amount)}'),
            _DetailRow(
                label: 'Date',
                value: FormatUtil.formatDateTime(tx.timestamp)),
            _DetailRow(
                label: 'Status',
                value: tx.status.replaceAll('_', ' ')),
            if (tx.syncedAt != null)
              _DetailRow(
                  label: 'Synced At',
                  value: FormatUtil.formatDateTime(tx.syncedAt!)),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Transaction History'),
            elevation: 0,
          ),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _controller.loadData,
                  child: Column(
                    children: [
                      _FilterBar(
                        selected: _filterStatus,
                        onSelected: (v) =>
                            setState(() => _filterStatus = v),
                      ),
                      Expanded(
                        child: _filtered.isEmpty
                            ? _EmptyState()
                            : ListView.builder(
                                itemCount: _filtered.length,
                                itemBuilder: (context, index) =>
                                    HistoryTransactionTile(
                                  transaction: _filtered[index],
                                  currentUserId: _controller.userId,
                                  onTap: () => _showTransactionDetails(
                                      _filtered[index]),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final void Function(String) onSelected;

  const _FilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const filters = ['ALL', 'SENT', 'RECEIVED', 'PENDING'];
    const labels = ['All', 'Sent', 'Received', 'Pending'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < filters.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            FilterChip(
              label: Text(labels[i]),
              selected: selected == filters[i],
              onSelected: (_) => onSelected(filters[i]),
              backgroundColor: Colors.transparent,
              side: BorderSide(
                color: selected == filters[i]
                    ? const Color(0xFF2563EB)
                    : Colors.grey[300]!,
                width: 2,
              ),
              labelStyle: TextStyle(
                color: selected == filters[i]
                    ? const Color(0xFF2563EB)
                    : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
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
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
