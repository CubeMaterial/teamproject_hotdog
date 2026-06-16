import 'package:flutter/material.dart';

class DashboardDateRangePicker extends StatelessWidget {
  const DashboardDateRangePicker({
    super.key,
    this.label = '기간',
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(label),
    );
  }
}
