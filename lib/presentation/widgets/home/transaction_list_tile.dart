import 'package:flutter/material.dart';
import '../../../data/models/transaction_model.dart';
import '../../../domain/utils/format_util.dart';

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
    final isPending = transaction.status == 'PENDING_SYNC';

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFFCD34D).withValues(alpha: 0.3)
                      : const Color(0xFFD1FAE5).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isPending ? 'Pending' : 'Synced',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isPending
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
  }
}
