import 'package:flutter/material.dart';

import '../../../../../domain/entities/member.dart';

class MemberDetailDialog extends StatelessWidget {
  const MemberDetailDialog({super.key, required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(member.name),
      content: Text('${member.email} / ${member.status}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
