import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

import '../../../../../domain/entities/dashboard_summary.dart';

class TopSellingProductsCard extends StatelessWidget {
  const TopSellingProductsCard({super.key, required this.products});

  final List<TopSellingProduct> products;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '인기 상품 TOP 5',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '전주 월요일부터 일요일까지',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            for (final (index, product) in products.indexed) ...[
              _TopSellingProductRow(rank: index + 1, product: product),
              if (index != products.length - 1) const Divider(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopSellingProductRow extends StatelessWidget {
  const _TopSellingProductRow({required this.rank, required this.product});

  final int rank;
  final TopSellingProduct product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '$rank',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: Text(
            product.name,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_formatNumber(product.quantity)}개',
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              '${_formatNumber(product.salesAmount)}원',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }
    return buffer.toString();
  }
}
