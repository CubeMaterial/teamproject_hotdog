import 'package:flutter/material.dart';

import '../../../../../domain/entities/inventory.dart';

class StockAdjustDialog extends StatelessWidget {
  const StockAdjustDialog({super.key, required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${item.name} 재고 조정'),
      content: Text('현재 재고: ${item.stock}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
