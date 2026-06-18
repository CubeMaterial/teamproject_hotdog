import 'package:flutter/material.dart';

import '../../../view_models/refund_view_model.dart';
import '../../../widgets/dashboard_paginated_section.dart';
import '../../../widgets/dashboard_tab_header.dart';
import 'widgets/refund_filter_bar.dart';
import 'widgets/refund_table.dart';

class RefundTab extends StatelessWidget {
  const RefundTab({super.key, required this.viewModel});

  final RefundViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const DashboardTabHeader(
          title: '환불 관리',
          subtitle: '환불 요청과 처리 상태를 관리합니다.',
        ),
        const SizedBox(height: 16),
        DashboardPaginatedSection(
          items: viewModel.refunds,
          headerBuilder: (pageSizeSelector) =>
              RefundFilterBar(pageSizeSelector: pageSizeSelector),
          tableBuilder: (refunds) => RefundTable(
            refunds: refunds,
            onStatusChanged: viewModel.updateStatus,
          ),
        ),
      ],
    );
  }
}
