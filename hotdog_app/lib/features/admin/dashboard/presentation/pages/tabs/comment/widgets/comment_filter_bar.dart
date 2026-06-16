import 'package:flutter/material.dart';

import '../../../../widgets/dashboard_search_field.dart';

class CommentFilterBar extends StatelessWidget {
  const CommentFilterBar({super.key, this.pageSizeSelector, this.trailing});

  final Widget? pageSizeSelector;
  final Widget? trailing;

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
              const DashboardSearchField(hintText: '게시글, 작성자, 내용 검색'),
              ?pageSizeSelector,
              ?trailing,
            ],
          );
        }

        return Row(
          children: [
            const Flexible(
              fit: FlexFit.loose,
              child: DashboardSearchField(hintText: '게시글, 작성자, 내용 검색'),
            ),
            const Spacer(),
            ?pageSizeSelector,
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        );
      },
    );
  }
}
