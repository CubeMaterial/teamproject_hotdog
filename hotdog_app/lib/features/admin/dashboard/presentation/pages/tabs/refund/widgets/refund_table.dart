import 'package:flutter/material.dart';

import '../../../../../domain/entities/refund.dart';
import '../../../../widgets/dashboard_data_table.dart';
import 'refund_detail_dialog.dart';
import 'refund_status_badge.dart';

class RefundTable extends StatelessWidget {
  const RefundTable({
    super.key,
    required this.refunds,
    required this.onStatusChanged,
  });

  final List<Refund> refunds;
  final Future<void> Function({
    required String refundId,
    required String action,
  })
  onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return DashboardDataTable(
      columns: const ['주문번호', '회원', '상품', '금액', '상태', '요청일'],
      numericColumnIndexes: const {3},
      onRowTap: (index) => _showRefundDetail(context, refunds[index]),
      rows: [
        for (final refund in refunds)
          [
            Text(refund.orderNumber),
            Align(
              alignment: Alignment.center,
              child: Text(refund.memberName, textAlign: TextAlign.center),
            ),
            Text(_truncate(refund.itemName)),
            DashboardNumberText(refund.amount, suffix: '원'),
            Align(
              alignment: Alignment.center,
              child: RefundStatusBadge(label: refund.status),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatDate(refund.requestedAt),
                textAlign: TextAlign.right,
              ),
            ),
          ],
      ],
    );
  }

  void _showRefundDetail(BuildContext context, Refund refund) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return RefundDetailDialog(
          refund: refund,
          onStatusChanged: onStatusChanged,
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
