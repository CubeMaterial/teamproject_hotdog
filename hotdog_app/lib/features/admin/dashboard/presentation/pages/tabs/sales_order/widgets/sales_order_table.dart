import 'package:flutter/material.dart';

import '../../../../../domain/entities/sales_order.dart';
import '../../../../widgets/dashboard_data_table.dart';
import '../../../../widgets/dashboard_text_detail_dialog.dart';
import 'sales_order_status_badge.dart';

class SalesOrderTable extends StatelessWidget {
  const SalesOrderTable({super.key, required this.orders});

  final List<SalesOrder> orders;

  @override
  Widget build(BuildContext context) {
    return DashboardDataTable(
      columns: const ['주문번호', '상품명', '회원', '금액', '상태', '주문일'],
      numericColumnIndexes: const {3},
      rows: [
        for (final order in orders)
          [
            Text(order.orderNumber),
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
              child: Text(order.memberName, textAlign: TextAlign.center),
            ),
            DashboardNumberText(order.totalPrice, suffix: '원'),
            Align(
              alignment: Alignment.center,
              child: SalesOrderStatusBadge(label: order.status),
            ),
            Text(_formatDate(order.orderedAt)),
          ],
      ],
    );
  }

  void _showOrderDetail(BuildContext context, SalesOrder order) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return DashboardTextDetailDialog(
          title: '수주 상세',
          items: [
            DashboardTextDetailItem(label: '주문번호', value: order.orderNumber),
            DashboardTextDetailItem(label: '상품명', value: order.itemName),
            DashboardTextDetailItem(label: '회원', value: order.memberName),
            DashboardTextDetailItem(
              label: '금액',
              value: '${_formatNumber(order.totalPrice)}원',
            ),
            DashboardTextDetailItem(label: '상태', value: order.status),
            DashboardTextDetailItem(
              label: '주문일',
              value: _formatDate(order.orderedAt),
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

  String _formatNumber(int value) {
    final sign = value < 0 ? '-' : '';
    final text = value.abs().toString();
    final buffer = StringBuffer(sign);

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }

    return buffer.toString();
  }
}
