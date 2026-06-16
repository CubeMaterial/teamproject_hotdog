import 'package:flutter/material.dart';

import '../../../view_models/member_view_model.dart';
import '../../../widgets/dashboard_paginated_section.dart';
import '../../../widgets/dashboard_tab_header.dart';
import 'widgets/member_filter_bar.dart';
import 'widgets/member_table.dart';

class MemberManageTab extends StatelessWidget {
  const MemberManageTab({super.key, required this.viewModel});

  final MemberViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const DashboardTabHeader(
          title: '회원 관리',
          subtitle: '회원 상태와 가입 정보를 확인합니다.',
        ),
        const SizedBox(height: 16),
        const MemberFilterBar(),
        const SizedBox(height: 16),
        DashboardPaginatedSection(
          items: viewModel.members,
          tableBuilder: (members) => MemberTable(members: members),
        ),
      ],
    );
  }
}
