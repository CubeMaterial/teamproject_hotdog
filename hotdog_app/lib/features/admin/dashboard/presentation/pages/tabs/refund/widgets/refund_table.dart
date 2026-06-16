import 'package:flutter/material.dart';

import '../../../../../domain/entities/refund.dart';
import '../../../../widgets/dashboard_data_table.dart';
import 'refund_status_badge.dart';

class RefundTable extends StatelessWidget {
  const RefundTable({super.key, required this.refunds});

  final List<Refund> refunds;

  @override
  Widget build(BuildContext context) {
    return DashboardDataTable(
      columns: const ['주문번호', '회원', '금액', '상태', '요청일'],
      numericColumnIndexes: const {2},
      rows: [
        for (final refund in refunds)
          [
            Text(refund.orderNumber),
            Align(
              alignment: Alignment.center,
              child: Text(refund.memberName, textAlign: TextAlign.center),
            ),
            DashboardNumberText(refund.amount, suffix: '원'),
            Align(
              alignment: Alignment.center,
              child: RefundStatusBadge(label: refund.status),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${refund.requestedAt.year}-${refund.requestedAt.month}-${refund.requestedAt.day}',
                textAlign: TextAlign.right,
              ),
            ),
          ],
      ],
    );
  }
}
