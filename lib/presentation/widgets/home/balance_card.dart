import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../data/dto/auth_response.dart';
import '../../../domain/utils/format_util.dart';

class BalanceCard extends StatelessWidget {
  final AuthResponse user;

  const BalanceCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final available = user.balance - user.pendingOfflineAmount;

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${user.username}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Total Balance',
            style: TextStyle(color: Colors.white70, fontSize: 11.sp),
          ),
          SizedBox(height: 1.h),
          Text(
            '₦${FormatUtil.formatCurrencyWithComma(user.balance)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 11.sp),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '₦${FormatUtil.formatCurrency(available)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 11.sp),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '₦${FormatUtil.formatCurrency(user.pendingOfflineAmount)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
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
    );
  }
}
