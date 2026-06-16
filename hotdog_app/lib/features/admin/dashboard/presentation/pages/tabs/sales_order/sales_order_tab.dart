import 'package:flutter/material.dart';

import '../../../view_models/sales_order_view_model.dart';
import '../../../widgets/dashboard_paginated_section.dart';
import '../../../widgets/dashboard_tab_header.dart';
import 'widgets/sales_order_filter_bar.dart';
import 'widgets/sales_order_table.dart';

class SalesOrderTab extends StatelessWidget {
  const SalesOrderTab({super.key, required this.viewModel});

  final SalesOrderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const DashboardTabHeader(
          title: '판매 주문',
          subtitle: '판매 주문의 결제와 배송 상태를 관리합니다.',
        ),
        const SizedBox(height: 16),
        DashboardPaginatedSection(
          items: viewModel.orders,
          headerBuilder: (pageSizeSelector) =>
              SalesOrderFilterBar(pageSizeSelector: pageSizeSelector),
          tableBuilder: (orders) => SalesOrderTable(orders: orders),
        ),
      ],
    );
  }
}
