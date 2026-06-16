import 'package:flutter/material.dart';

import '../../../view_models/inventory_view_model.dart';
import '../../../widgets/dashboard_paginated_section.dart';
import '../../../widgets/dashboard_tab_header.dart';
import 'widgets/inventory_filter_bar.dart';
import 'widgets/inventory_table.dart';

class InventoryTab extends StatefulWidget {
  const InventoryTab({super.key, required this.viewModel});

  final InventoryViewModel viewModel;

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.ensureLoaded();
    });
  }

  @override
  void didUpdateWidget(covariant InventoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.viewModel.ensureLoaded();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const DashboardTabHeader(
          title: '재고 관리',
          subtitle: '상품별 재고와 상태를 확인합니다.',
        ),
        const SizedBox(height: 16),
        InventoryFilterBar(
          categories: widget.viewModel.categories,
          selectedCategory: widget.viewModel.selectedCategory,
          onSearchChanged: widget.viewModel.setSearchQuery,
          onCategoryChanged: widget.viewModel.setSelectedCategory,
        ),
        const SizedBox(height: 16),
        DashboardPaginatedSection(
          items: widget.viewModel.filteredItems,
          tableBuilder: (items) => InventoryTable(
            items: items,
            selectedItemIds: widget.viewModel.selectedItemIds,
            onSelectionChanged: widget.viewModel.setItemSelected,
            onAllSelectionChanged: (selected) {
              widget.viewModel.setItemsSelected(
                items.map((item) => item.id),
                selected,
              );
            },
          ),
        ),
      ],
    );
  }
}
