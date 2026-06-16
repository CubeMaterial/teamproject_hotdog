import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

class WeeklySalesChart extends StatelessWidget {
  const WeeklySalesChart({super.key, required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final chartValues = _recentSixDayValues();
    final rawMaxValue = chartValues.reduce((a, b) => a > b ? a : b);
    final maxValue = rawMaxValue <= 0 ? 1 : rawMaxValue;
    final totalSales = chartValues.fold<int>(
      0,
      (total, value) => total + value,
    );
    final labels = _recentSixDayLabels();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('(단위: 원)', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Card(
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
                Row(
                  children: [
                    Text(
                      '매출 그래프',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    _ChartLegend(
                      label: '최근 6일 매출',
                      value: _formatNumber(totalSales),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 180,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final (index, value) in chartValues.indexed)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _formatNumber(value),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: FractionallySizedBox(
                                    heightFactor: (value / maxValue).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    alignment: Alignment.bottomCenter,
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: AppColors.deepOrange,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  index < labels.length ? labels[index] : '',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

  List<int> _recentSixDayValues() {
    final normalizedValues = values.map((value) => value < 0 ? 0 : value);
    final result = normalizedValues.take(6).toList();

    while (result.length < 6) {
      result.add(0);
    }

    return result;
  }

  List<String> _recentSixDayLabels() {
    final today = DateTime.now();

    return [
      for (var daysAgo = 6; daysAgo >= 1; daysAgo--)
        '${today.subtract(Duration(days: daysAgo)).day}일',
    ];
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.deepOrange,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(width: 10),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
