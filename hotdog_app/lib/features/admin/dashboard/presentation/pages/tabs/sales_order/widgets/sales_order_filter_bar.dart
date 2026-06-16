import 'package:flutter/material.dart';

import '../../../../widgets/dashboard_date_range_picker.dart';
import '../../../../widgets/dashboard_search_field.dart';

class SalesOrderFilterBar extends StatelessWidget {
  const SalesOrderFilterBar({super.key, this.pageSizeSelector});

  final Widget? pageSizeSelector;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasRoomForSingleLine = constraints.maxWidth >= 620;

        if (!hasRoomForSingleLine) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const DashboardSearchField(hintText: '주문번호, 회원 검색'),
              const DashboardDateRangePicker(label: '주문일'),
              ?pageSizeSelector,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              fit: FlexFit.loose,
              child: DashboardSearchField(hintText: '주문번호, 회원 검색'),
            ),
            const SizedBox(width: 8),
            // const DashboardDateRangePicker(label: '주문일'),
            const Spacer(),
            ?pageSizeSelector,
          ],
        );
      },
    );
  }
}
