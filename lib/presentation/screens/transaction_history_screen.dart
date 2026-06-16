import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/utils/format_util.dart';
import '../blocs/transaction_history/transaction_history_bloc.dart';
import '../widgets/transaction_history/history_transaction_tile.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransactionHistoryBloc(),
      child: const _TransactionHistoryView(),
    );
  }
}

class _TransactionHistoryView extends StatelessWidget {
  const _TransactionHistoryView();

  void _showTransactionDetails(
      BuildContext context, TransactionModel tx, String userId) {
    final isSent = tx.senderId == userId;

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
    return BlocBuilder<TransactionHistoryBloc, TransactionHistoryState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Transaction History'),
            elevation: 0,
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async => context
                      .read<TransactionHistoryBloc>()
                      .add(TransactionHistoryLoadRequested()),
                  child: Column(
                    children: [
                      _FilterBar(
                        selected: state.filterStatus,
                        onSelected: (v) => context
                            .read<TransactionHistoryBloc>()
                            .add(TransactionHistoryFilterChanged(v)),
                      ),
                      Expanded(
                        child: state.filtered.isEmpty
                            ? const _EmptyState()
                            : ListView.builder(
                                itemCount: state.filtered.length,
                                itemBuilder: (context, index) =>
                                    HistoryTransactionTile(
                                  transaction: state.filtered[index],
                                  currentUserId: state.userId,
                                  onTap: () => _showTransactionDetails(
                                      context,
                                      state.filtered[index],
                                      state.userId),
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
  const _EmptyState();

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
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
