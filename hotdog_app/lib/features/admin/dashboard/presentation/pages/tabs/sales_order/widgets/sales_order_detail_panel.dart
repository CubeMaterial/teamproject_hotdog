import 'package:flutter/material.dart';

import '../../../../../domain/entities/sales_order.dart';

class SalesOrderDetailPanel extends StatelessWidget {
  const SalesOrderDetailPanel({super.key, required this.order});

  final SalesOrder order;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(order.orderNumber),
      subtitle: Text('${order.memberName} / ${order.totalPrice}원'),
      trailing: Text(order.status),
    );
  }
}
