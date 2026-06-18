import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

import '../../../../widgets/dashboard_status_badge.dart';

class RefundStatusBadge extends StatelessWidget {
  const RefundStatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DashboardStatusBadge(label: label, color: _colorFor(label));
  }

  Color _colorFor(String status) {
    if (status == '환불완료') {
      return AppColors.success;
    }
    if (status == '환불신청') {
      return AppColors.deepOrange;
    }
    if (status == '환불보류') {
      return const Color(0xFFF2B705);
    }
    if (status == '환불취소') {
      return const Color(0xFF795548);
    }
    return AppColors.neutral;
  }
}
