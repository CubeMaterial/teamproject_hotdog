import 'package:flutter/material.dart';

import '../../../../../domain/entities/member.dart';
import '../../../../widgets/dashboard_data_table.dart';
import 'member_status_badge.dart';

class MemberTable extends StatelessWidget {
  const MemberTable({super.key, required this.members});

  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    return DashboardDataTable(
      columns: const ['이름', '이메일', '연락처', '상태', '가입일'],
      rows: [
        for (final member in members)
          [
            Text(member.name),
            Text(member.email),
            Text(_formatPhoneNumber(member.phone)),
            MemberStatusBadge(label: member.status),
            Text(_formatDate(member.joinedAt)),
          ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatPhoneNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }

    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }

    return value;
  }
}
