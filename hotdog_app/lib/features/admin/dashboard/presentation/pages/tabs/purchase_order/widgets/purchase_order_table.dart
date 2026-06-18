import 'package:flutter/material.dart';

import '../../../../../domain/entities/purchase_order.dart';
import '../../../../widgets/dashboard_data_table.dart';
import '../../../../widgets/dashboard_text_detail_dialog.dart';
import 'purchase_order_status_badge.dart';

class PurchaseOrderTable extends StatelessWidget {
  const PurchaseOrderTable({super.key, required this.orders});

  final List<PurchaseOrder> orders;

  @override
  Widget build(BuildContext context) {
    return DashboardDataTable(
      columns: const ['거래처', '품목', '수량', '상태', '발주일'],
      rows: [
        for (final order in orders)
          [
            Text(order.vendor),
            TextButton(
              onPressed: () => _showOrderDetail(context, order),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF333333),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: Text(_truncate(order.itemName)),
            ),
            Align(
              alignment: Alignment.center,
              child: Text('${order.quantity}', textAlign: TextAlign.center),
            ),
            Align(
              alignment: Alignment.center,
              child: PurchaseOrderStatusBadge(label: order.status),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                _formatDate(order.createdAt),
                textAlign: TextAlign.center,
              ),
            ),
          ],
      ],
    );
  }

  void _showOrderDetail(BuildContext context, PurchaseOrder order) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return DashboardTextDetailDialog(
          title: '발주 상세',
          items: [
            DashboardTextDetailItem(label: '거래처', value: order.vendor),
            DashboardTextDetailItem(label: '품목', value: order.itemName),
            DashboardTextDetailItem(label: '수량', value: '${order.quantity}'),
            DashboardTextDetailItem(label: '상태', value: order.status),
            DashboardTextDetailItem(
              label: '발주일',
              value: _formatDate(order.createdAt),
            ),
          ],
        );
      },
    );
  }

  String _truncate(String text) {
    const maxLength = 20;
    final trimmedText = text.trim();

    if (trimmedText.length <= maxLength) {
      return trimmedText;
    }

    return '${trimmedText.substring(0, maxLength)}...';
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
