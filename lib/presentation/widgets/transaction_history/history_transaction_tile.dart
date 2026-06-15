import 'package:flutter/material.dart';
import '../../../data/models/transaction_model.dart';
import '../../../domain/utils/format_util.dart';

class HistoryTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final String currentUserId;
  final VoidCallback onTap;

  const HistoryTransactionTile({
    super.key,
    required this.transaction,
    required this.currentUserId,
    required this.onTap,
  });

  Color get _statusBgColor {
    switch (transaction.status) {
      case 'PENDING_SYNC':
        return const Color(0xFFFCD34D).withValues(alpha: 0.3);
      case 'COMPLETED':
        return const Color(0xFFD1FAE5).withValues(alpha: 0.5);
      default:
        return const Color(0xFFFECACA).withValues(alpha: 0.5);
    }
  }

  Color get _statusTextColor {
    switch (transaction.status) {
      case 'PENDING_SYNC':
        return const Color(0xFFB45309);
      case 'COMPLETED':
        return const Color(0xFF047857);
      default:
        return const Color(0xFFDC2626);
    }
  }

  String get _statusLabel {
    switch (transaction.status) {
      case 'PENDING_SYNC':
        return 'Pending Sync';
      case 'COMPLETED':
        return 'Completed';
      default:
        return transaction.status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSent = transaction.senderId == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSent
                            ? 'Sent to ${FormatUtil.formatUserId(transaction.receiverId)}'
                            : 'Received from ${FormatUtil.formatUserId(transaction.senderId)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FormatUtil.formatDateTime(transaction.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusBgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _statusTextColor,
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
                      '${isSent ? '-' : '+'}₦${FormatUtil.formatCurrency(transaction.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isSent
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(Icons.chevron_right,
                        color: Colors.grey[400], size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
