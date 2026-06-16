import 'package:flutter/material.dart';

import '../../../../domain/entities/inventory.dart';
import '../../../view_models/inventory_view_model.dart';
import '../../../widgets/dashboard_data_table.dart';
import '../../../widgets/dashboard_paginated_section.dart';
import '../../../widgets/dashboard_status_badge.dart';
import '../../../widgets/dashboard_tab_header.dart';

class StockHistoryTab extends StatelessWidget {
  const StockHistoryTab({super.key, required this.viewModel});

  final InventoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const DashboardTabHeader(
          title: '입출고 내역',
          subtitle: '상품별 입고와 출고 이력을 확인합니다.',
        ),
        const SizedBox(height: 16),
        DashboardPaginatedSection(
          items: viewModel.histories,
          tableBuilder: (items) => _StockHistoryTable(items: items),
        ),
      ],
    );
  }
}

class _StockHistoryTable extends StatelessWidget {
  const _StockHistoryTable({required this.items});

  final List<StockHistory> items;

  @override
  Widget build(BuildContext context) {
    return DashboardDataTable(
      columns: const ['번호', '상품', '카테고리', '구분', '수량', '상태'],
      numericColumnIndexes: const {0, 4},
      rows: [
        for (final item in items)
          [
            Text(item.id),
            SizedBox(
              width: 360,
              child: Text(item.itemName, overflow: TextOverflow.ellipsis),
            ),
            Text(item.category),
            _StockTypeBadge(label: item.type),
            DashboardNumberText(item.quantity),
            Text(item.status),
          ],
      ],
    );
  }
}

class _StockTypeBadge extends DashboardStatusBadge {
  const _StockTypeBadge({required super.label})
    : super(
        color: label == '입고'
            ? const Color(0xFF15803D)
            : const Color(0xFFC2410C),
      );
}
