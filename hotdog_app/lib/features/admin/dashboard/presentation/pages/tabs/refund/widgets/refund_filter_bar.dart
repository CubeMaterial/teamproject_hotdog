import 'package:flutter/material.dart';

import '../../../../widgets/dashboard_date_range_picker.dart';
import '../../../../widgets/dashboard_search_field.dart';

class RefundFilterBar extends StatelessWidget {
  const RefundFilterBar({super.key, this.pageSizeSelector});

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
              const DashboardDateRangePicker(label: '요청일'),
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
            const Spacer(),
            ?pageSizeSelector,
          ],
        );
      },
    );
  }
}
