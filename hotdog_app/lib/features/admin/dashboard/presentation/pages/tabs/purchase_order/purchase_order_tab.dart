import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

import '../../../view_models/purchase_order_view_model.dart';
import '../../../widgets/dashboard_paginated_section.dart';
import '../../../widgets/dashboard_tab_header.dart';
import 'widgets/purchase_order_filter_bar.dart';
import 'widgets/purchase_order_form_dialog.dart';
import 'widgets/purchase_order_table.dart';

class PurchaseOrderTab extends StatelessWidget {
  const PurchaseOrderTab({super.key, required this.viewModel});

  final PurchaseOrderViewModel viewModel;

  Future<void> _openPurchaseOrderForm(BuildContext context) async {
    final formData = await showGeneralDialog<PurchaseOrderFormData>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) =>
          const PurchaseOrderFormDialog(),
    );

    if (formData == null || !context.mounted) {
      return;
    }

    try {
      await viewModel.createOrder(
        vendor: formData.vendor,
        itemName: formData.itemName,
        quantity: formData.quantity,
        createdAt: formData.createdAt,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('발주 등록이 완료되었습니다.')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('발주 등록 실패: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        DashboardTabHeader(
          title: '발주 관리',
          subtitle: '거래처 발주와 입고 상태를 관리합니다.',
          actions: [
            SizedBox(
              height: 45,
              child: FilledButton(
                onPressed: () => _openPurchaseOrderForm(context),
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
                      '발주 등록',
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
          items: viewModel.orders,
          headerBuilder: (pageSizeSelector) =>
              PurchaseOrderFilterBar(pageSizeSelector: pageSizeSelector),
          tableBuilder: (orders) => PurchaseOrderTable(orders: orders),
        ),
      ],
    );
  }
}
