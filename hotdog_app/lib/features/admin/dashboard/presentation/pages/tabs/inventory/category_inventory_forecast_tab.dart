import 'package:flutter/material.dart';

import '../../../view_models/inventory_view_model.dart';
import '../../../widgets/dashboard_data_table.dart';
import '../../../widgets/dashboard_paginated_section.dart';
import '../../../widgets/dashboard_tab_header.dart';

class CategoryInventoryForecastTab extends StatelessWidget {
  const CategoryInventoryForecastTab({super.key, required this.viewModel});

  final InventoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const DashboardTabHeader(
          title: '카테고리별 재고 예측',
          subtitle: '카테고리 기준으로 7일 후와 30일 후 예상 재고를 확인합니다.',
        ),
        const SizedBox(height: 16),
        DashboardPaginatedSection(
          items: viewModel.categoryForecasts,
          tableBuilder: (forecasts) =>
              _CategoryForecastTable(forecasts: forecasts),
        ),
      ],
    );
  }
}

class _CategoryForecastTable extends StatelessWidget {
  const _CategoryForecastTable({required this.forecasts});

  final List<CategoryInventoryForecast> forecasts;

  @override
  Widget build(BuildContext context) {
    return DashboardDataTable(
      columns: const ['카테고리', '7일 후', '30일 후'],
      numericColumnIndexes: const {1, 2},
      rows: [
        for (final forecast in forecasts)
          [
            SizedBox(
              width: 360,
              child: Text(forecast.category, overflow: TextOverflow.ellipsis),
            ),
            _ForecastValueText(value: forecast.predictedStockAfter7d),
            _ForecastValueText(value: forecast.predictedStockAfter30d),
          ],
      ],
    );
  }
}

class _ForecastValueText extends StatelessWidget {
  const _ForecastValueText({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: value == null ? '예측값 없음' : '카테고리별 예상 재고',
      child: Text(
        _format(value),
        textAlign: TextAlign.right,
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
