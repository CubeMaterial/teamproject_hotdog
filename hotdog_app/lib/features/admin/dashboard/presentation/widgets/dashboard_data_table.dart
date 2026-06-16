import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

class DashboardDataTable extends StatelessWidget {
  const DashboardDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.numericColumnIndexes = const {},
    this.columnSpacing,
    this.horizontalMargin,
    this.onRowTap,
    this.selectedRowIndexes = const {},
    this.onRowSelected,
  });

  final List<String> columns;
  final List<List<Widget>> rows;
  final Set<int> numericColumnIndexes;
  final double? columnSpacing;
  final double? horizontalMargin;
  final ValueChanged<int>? onRowTap;
  final Set<int> selectedRowIndexes;
  final void Function(int index, bool selected)? onRowSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: columnSpacing,
                horizontalMargin: horizontalMargin,
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w800),
                columns: [
                  for (final column in columns)
                    DataColumn(
                      numeric: false,
                      headingRowAlignment: MainAxisAlignment.center,
                      label: Center(
                        child: Text(column, textAlign: TextAlign.center),
                      ),
                    ),
                ],
                rows: [
                  for (final (index, row) in rows.indexed)
                    DataRow(
                      selected: selectedRowIndexes.contains(index),
                      onSelectChanged: onRowSelected != null
                          ? (selected) =>
                                onRowSelected!(index, selected ?? false)
                          : onRowTap == null
                          ? null
                          : (_) => onRowTap!(index),
                      cells: _buildCells(row),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<DataCell> _buildCells(List<Widget> row) {
    return [
      for (final (index, cell) in row.indexed)
        DataCell(
          numericColumnIndexes.contains(index)
              ? Align(alignment: Alignment.centerRight, child: cell)
              : cell,
        ),
    ];
  }
}

class DashboardNumberText extends StatelessWidget {
  const DashboardNumberText(this.value, {super.key, this.suffix = ''});

  final int value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_formatNumber(value)}$suffix',
      textAlign: TextAlign.right,
      overflow: TextOverflow.ellipsis,
    );
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
