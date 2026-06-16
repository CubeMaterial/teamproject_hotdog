import 'package:flutter/material.dart';

import '../../../../../domain/entities/refund.dart';

class RefundDetailDialog extends StatelessWidget {
  const RefundDetailDialog({super.key, required this.refund});

  final Refund refund;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(refund.orderNumber),
      content: Text(
        '${refund.memberName} / ${refund.amount}원 / ${refund.status}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
