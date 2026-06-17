import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
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
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Color(0xFFD97706)),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Sync',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                    color: const Color(0xFFD97706),
                  ),
                ),
                Text(
                  '$count transactions waiting to sync '
                  '(₦${FormatUtil.formatCurrency(amount)})',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFFB45309),
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
