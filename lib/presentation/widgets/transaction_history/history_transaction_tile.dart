import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
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
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
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
                    size: 5.w,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSent
                            ? 'Sent to ${FormatUtil.formatUserId(transaction.receiverId)}'
                            : 'Received from ${FormatUtil.formatUserId(transaction.senderId)}',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        FormatUtil.formatDateTime(transaction.timestamp),
                        style: TextStyle(
                            fontSize: 11.sp, color: Colors.grey[500]),
                      ),
                      SizedBox(height: 0.5.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.3.h),
                        decoration: BoxDecoration(
                          color: _statusBgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                            color: _statusTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 3.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isSent ? '-' : '+'}₦${FormatUtil.formatCurrency(transaction.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                        color: isSent
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Icon(Icons.chevron_right,
                        color: Colors.grey[400], size: 5.w),
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
