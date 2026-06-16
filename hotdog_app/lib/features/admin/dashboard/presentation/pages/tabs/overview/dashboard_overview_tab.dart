import 'package:flutter/material.dart';

import '../../../view_models/dashboard_view_model.dart';
import '../../../widgets/dashboard_tab_header.dart';
import 'widgets/summary_metric_card.dart';
import 'widgets/weekly_sales_chart.dart';

class DashboardOverviewTab extends StatelessWidget {
  const DashboardOverviewTab({super.key, required this.viewModel});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final summary = viewModel.summary;
    if (summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const DashboardTabHeader(
          title: '대시보드 개요',
          subtitle: '매출과 환불, 커뮤니티 현황을 빠르게 확인합니다.',
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < 760
                ? constraints.maxWidth
                : (constraints.maxWidth - 36) / 4;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: SummaryMetricCard(
                    title: '오늘 매출',
                    value: _currency(summary.todaySales),
                    icon: Icons.payments_outlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: SummaryMetricCard(
                    title: '한달 매출',
                    value: _currency(summary.monthSales),
                    icon: Icons.calendar_month_outlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: SummaryMetricCard(
                    title: '환불건수',
                    value: '${_number(summary.refundCount)}건',
                    icon: Icons.assignment_return_outlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: SummaryMetricCard(
                    title: '오늘 게시글 수',
                    value: '${_number(summary.todayPostCount)}건',
                    icon: Icons.article_outlined,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        WeeklySalesChart(values: summary.weeklySales),
      ],
    );
  }

  String _currency(int amount) => '${_number(amount)}원';

  String _number(int value) {
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
