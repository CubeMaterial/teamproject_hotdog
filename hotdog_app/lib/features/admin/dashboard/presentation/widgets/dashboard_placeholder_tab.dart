import 'package:flutter/material.dart';

import 'dashboard_tab_header.dart';

class DashboardPlaceholderTab extends StatelessWidget {
  const DashboardPlaceholderTab({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        DashboardTabHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 16),
        const Text('준비 중입니다.'),
      ],
    );
  }
}
