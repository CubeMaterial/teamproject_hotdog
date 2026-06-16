import 'package:flutter/material.dart';

class StaffFilterBar extends StatelessWidget {
  const StaffFilterBar({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onNameChanged,
    this.pageSizeSelector,
  });

  final String selectedRole;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<String> onNameChanged;
  final Widget? pageSizeSelector;

  @override
  Widget build(BuildContext context) {
    final roleFilter = SizedBox(
      width: 180,
      child: DropdownButtonFormField<String>(
        initialValue: selectedRole,
        isDense: true,
        decoration: InputDecoration(
          labelText: '직급',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        items: const [
          DropdownMenuItem(value: '전체', child: Text('전체')),
          DropdownMenuItem(value: '사원', child: Text('사원')),
          DropdownMenuItem(value: '주임', child: Text('주임')),
          DropdownMenuItem(value: '대리', child: Text('대리')),
        ],
        onChanged: onRoleChanged,
      ),
    );
    final nameFilter = SizedBox(
      width: 260,
      child: TextField(
        onChanged: onNameChanged,
        decoration: InputDecoration(
          labelText: '직원 이름',
          hintText: '이름 검색',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasRoomForSingleLine = constraints.maxWidth >= 760;

        if (!hasRoomForSingleLine) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [roleFilter, nameFilter, ?pageSizeSelector],
          );
        }

        return Row(
          children: [
            roleFilter,
            const SizedBox(width: 8),
            nameFilter,
            const Spacer(),
            ?pageSizeSelector,
          ],
        );
      },
    );
  }
}
