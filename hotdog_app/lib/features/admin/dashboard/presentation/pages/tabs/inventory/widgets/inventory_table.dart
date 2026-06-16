import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

import '../../../../../domain/entities/inventory.dart';
import 'stock_status_badge.dart';

class InventoryTable extends StatelessWidget {
  const InventoryTable({
    super.key,
    required this.items,
    required this.selectedItemIds,
    required this.onSelectionChanged,
    required this.onAllSelectionChanged,
  });

  final List<InventoryItem> items;
  final Set<String> selectedItemIds;
  final void Function(String itemId, bool selected) onSelectionChanged;
  final ValueChanged<bool> onAllSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final selectedVisibleCount = items
        .where((item) => selectedItemIds.contains(item.id))
        .length;
    final allSelected =
        items.isNotEmpty && selectedVisibleCount == items.length;
    final partiallySelected = selectedVisibleCount > 0 && !allSelected;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth < 960
              ? 960.0
              : constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(48),
                  1: FixedColumnWidth(64),
                  2: FlexColumnWidth(),
                  3: FixedColumnWidth(120),
                  4: FixedColumnWidth(96),
                  5: FixedColumnWidth(112),
                  6: FixedColumnWidth(120),
                  7: FixedColumnWidth(120),
                  8: FixedColumnWidth(112),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children: [
                      _HeaderCheckboxCell(
                        value: partiallySelected ? null : allSelected,
                        onChanged: items.isEmpty
                            ? null
                            : (value) => onAllSelectionChanged(value ?? false),
                      ),
                      const _HeaderCell('번호'),
                      const _HeaderCell('상품'),
                      const _HeaderCell('카테고리'),
                      const _HeaderCell('재고'),
                      const _HeaderCell('상태'),
                      const _HeaderCell('7일 예측'),
                      const _HeaderCell('30일 예측'),
                      const _HeaderCell('위험도'),
                    ],
                  ),
                  for (final item in items)
                    TableRow(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      children: [
                        _BodyCell(
                          child: Checkbox(
                            value: selectedItemIds.contains(item.id),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            onChanged: (value) {
                              onSelectionChanged(item.id, value ?? false);
                            },
                          ),
                        ),
                        _BodyCell(child: Text(item.id)),
                        _BodyCell(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _BodyCell(child: Text(item.category)),
                        _BodyCell(child: Text('${item.stock}')),
                        _BodyCell(child: StockStatusBadge(label: item.status)),
                        _BodyCell(
                          child: _ForecastValueText(
                            value: item.predictedStockAfter7d,
                          ),
                        ),
                        _BodyCell(
                          child: _ForecastValueText(
                            value: item.predictedStockAfter30d,
                          ),
                        ),
                        _BodyCell(
                          child: ForecastRiskBadge(
                            label: item.forecastRiskLabel,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCheckboxCell extends StatelessWidget {
  const _HeaderCheckboxCell({required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Center(
        child: Checkbox(
          value: value,
          tristate: true,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Align(
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _ForecastValueText extends StatelessWidget {
  const _ForecastValueText({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: value == null ? '예측값 없음' : '카테고리 기준 예상 재고',
      child: Text(
        _format(value),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _format(double? value) {
    if (value == null) {
      return '-';
    }

    final rounded = value.abs() >= 100
        ? value.round().toString()
        : value.toStringAsFixed(1);
    final parts = rounded.split('.');
    final whole = parts.first;
    final sign = whole.startsWith('-') ? '-' : '';
    final digits = sign.isEmpty ? whole : whole.substring(1);
    final buffer = StringBuffer(sign);

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }

    if (parts.length > 1) {
      buffer.write('.${parts.last}');
    }

    return buffer.toString();
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell({required this.child, this.alignment = Alignment.center});

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Align(alignment: alignment, child: child),
    );
  }
}
