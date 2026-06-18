import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

import '../../../../domain/entities/inventory.dart';
import '../../../view_models/inventory_view_model.dart';
import '../../../widgets/dashboard_data_table.dart';
import '../../../widgets/dashboard_paginated_section.dart';
import '../../../widgets/dashboard_tab_header.dart';
import 'widgets/item_form_dialog.dart';
import 'widgets/stock_status_badge.dart';

class ItemManageTab extends StatelessWidget {
  const ItemManageTab({super.key, required this.viewModel});

  final InventoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        DashboardTabHeader(
          title: '품목 관리',
          subtitle: '판매 품목과 카테고리 정보를 관리합니다.',
          actions: [
            SizedBox(
              // width: 120,
              height: 45,
              child: FilledButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => ItemFormDialog(
                    categories: viewModel.categories,
                    makers: viewModel.makers,
                    onSubmit: viewModel.createItem,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  minimumSize: const Size(0, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 22, color: Colors.white),
                    SizedBox(width: 2),
                    Text(
                      '품목 등록',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DashboardPaginatedSection(
          items: viewModel.items,
          tableBuilder: (items) => _ItemManageTable(items: items),
        ),
      ],
    );
  }
}

class _ItemManageTable extends StatelessWidget {
  const _ItemManageTable({required this.items});

  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    return DashboardDataTable(
      columns: const ['번호', '상품', '카테고리', '안전재고', '현재재고', '상태'],
      numericColumnIndexes: const {0, 3, 4},
      rows: [
        for (final item in items)
          [
            Text(item.id),
            SizedBox(
              width: 360,
              child: Text(item.name, overflow: TextOverflow.ellipsis),
            ),
            Text(item.category),
            DashboardNumberText(item.safeStock),
            DashboardNumberText(item.stock),
            StockStatusBadge(label: item.status),
          ],
      ],
    );
  }
}
