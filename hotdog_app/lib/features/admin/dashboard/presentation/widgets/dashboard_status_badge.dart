import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

class DashboardStatusBadge extends StatelessWidget {
  const DashboardStatusBadge({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? _colorFor(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _colorFor(String value) {
    if (value.contains('완료') || value.contains('정상') || value.contains('활성')) {
      return AppColors.success;
    }
    if (value.contains('대기') || value.contains('준비') || value.contains('검토')) {
      return AppColors.warning;
    }
    if (value.contains('부족') || value.contains('휴면')) {
      return AppColors.danger;
    }
    return AppColors.neutral;
  }
}
