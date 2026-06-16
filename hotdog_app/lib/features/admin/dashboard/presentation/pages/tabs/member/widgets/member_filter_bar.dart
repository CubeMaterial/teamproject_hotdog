import 'package:flutter/material.dart';

import '../../../../widgets/dashboard_search_field.dart';

class MemberFilterBar extends StatelessWidget {
  const MemberFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardSearchField(hintText: '회원명, 이메일 검색');
  }
}
