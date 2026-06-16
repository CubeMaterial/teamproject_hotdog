import 'package:flutter/material.dart';

import '../../../view_models/purchase_order_view_model.dart';
import '../../../widgets/dashboard_paginated_section.dart';
import '../../../widgets/dashboard_tab_header.dart';
import 'widgets/purchase_order_filter_bar.dart';
import 'widgets/purchase_order_form_dialog.dart';
import 'widgets/purchase_order_table.dart';

class PurchaseOrderTab extends StatelessWidget {
  const PurchaseOrderTab({super.key, required this.viewModel});

  final PurchaseOrderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        DashboardTabHeader(
          title: '발주 관리',
          subtitle: '거래처 발주와 입고 상태를 관리합니다.',
          actions: [
            FilledButton.icon(
              onPressed: () => showGeneralDialog<void>(
                context: context,
                barrierDismissible: true,
                barrierLabel: '닫기',
                transitionDuration: Duration.zero,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const PurchaseOrderFormDialog(),
              ),
              icon: const Icon(Icons.add),
              label: const Text('발주 등록'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DashboardPaginatedSection(
          items: viewModel.orders,
          headerBuilder: (pageSizeSelector) =>
              PurchaseOrderFilterBar(pageSizeSelector: pageSizeSelector),
          tableBuilder: (orders) => PurchaseOrderTable(orders: orders),
        ),
      ],
    );
  }
}
