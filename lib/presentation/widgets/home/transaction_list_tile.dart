import 'package:flutter/material.dart';
import '../../../data/models/transaction_model.dart';
import '../../../domain/utils/format_util.dart';

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'PENDING_SYNC' => (
          'Pending',
          const Color(0xFFFCD34D).withValues(alpha: 0.3),
          const Color(0xFFB45309),
        ),
      'INCOMING_PENDING' => (
          'Incoming',
          const Color(0xFFD1FAE5).withValues(alpha: 0.6),
          const Color(0xFF047857),
        ),
      _ => (
          'Synced',
          const Color(0xFFD1FAE5).withValues(alpha: 0.5),
          const Color(0xFF047857),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class TransactionListTile extends StatelessWidget {
  final TransactionModel transaction;
  final String currentUserId;

  const TransactionListTile({
    super.key,
    required this.transaction,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isSent = transaction.senderId == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSent
                  ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                  : const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSent ? Icons.arrow_upward : Icons.arrow_downward,
              color: isSent
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
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
                '${isSent ? '-' : '+'}₦${FormatUtil.formatCurrency(transaction.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSent
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              ),
              _StatusBadge(status: transaction.status),
            ],
          ),
        ),
      ),
    );
  }
}
