import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color borderColor;
  final Widget child;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB), size: 5.w),
              SizedBox(width: 2.w),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            subtitle,
            style: TextStyle(
                fontSize: 11.sp, color: const Color(0xFF6B7280)),
          ),
          SizedBox(height: 1.5.h),
          child,
        ],
      ),
    );
  }
}
