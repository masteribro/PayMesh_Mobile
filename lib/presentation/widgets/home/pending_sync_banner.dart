import 'package:flutter/material.dart';
import '../../../domain/utils/format_util.dart';

class PendingSyncBanner extends StatelessWidget {
  final int count;
  final double amount;

  const PendingSyncBanner({
    super.key,
    required this.count,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
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
                  '$count transactions waiting to sync '
                  '(₦${FormatUtil.formatCurrency(amount)})',
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
    );
  }
}
