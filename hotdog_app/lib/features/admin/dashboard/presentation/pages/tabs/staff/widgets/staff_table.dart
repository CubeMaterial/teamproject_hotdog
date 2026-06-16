import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

import '../../../../../domain/entities/staff.dart';

class StaffTable extends StatelessWidget {
  const StaffTable({
    super.key,
    required this.staffs,
    required this.selectedStaffIds,
    required this.onStaffSelected,
    required this.onAllStaffSelected,
  });

  final List<Staff> staffs;
  final Set<String> selectedStaffIds;
  final void Function(String staffSeq, bool selected) onStaffSelected;
  final ValueChanged<bool> onAllStaffSelected;

  bool get _allSelected =>
      staffs.isNotEmpty &&
      staffs.every((staff) => selectedStaffIds.contains(staff.staffSeq));

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth;
          const numberWidth = 20.0;
          final remainingWidth = tableWidth - numberWidth;
          final checkboxWidth = remainingWidth * 0.06;
          final nameWidth = remainingWidth * 0.16;
          final staffIdWidth = remainingWidth * 0.17;
          final phoneWidth = remainingWidth * 0.16;
          final roleWidth = remainingWidth * 0.11;
          final emailWidth = remainingWidth * 0.34;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: tableWidth),
              child: DataTable(
                horizontalMargin: 10,
                checkboxHorizontalMargin: 10,
                columnSpacing: 0,
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w800),
                columns: [
                  DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: SizedBox(
                      width: checkboxWidth,
                      child: Center(
                        child: Checkbox(
                          value: _allSelected,
                          onChanged: (selected) =>
                              onAllStaffSelected(selected ?? false),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: const _HeaderCell(width: numberWidth, label: '번호'),
                  ),
                  DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: _HeaderCell(width: nameWidth, label: '직원 이름'),
                  ),
                  DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: _HeaderCell(width: staffIdWidth, label: '사번'),
                  ),
                  DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: _HeaderCell(width: phoneWidth, label: '직원 연락처'),
                  ),
                  DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: _HeaderCell(width: roleWidth, label: '직급'),
                  ),
                  DataColumn(
                    headingRowAlignment: MainAxisAlignment.center,
                    label: _HeaderCell(width: emailWidth, label: '이메일'),
                  ),
                ],
                rows: [
                  for (final (index, staff) in staffs.indexed)
                    DataRow(
                      selected: selectedStaffIds.contains(staff.staffSeq),
                      cells: [
                        DataCell(
                          SizedBox(
                            width: checkboxWidth,
                            child: Center(
                              child: Checkbox(
                                value: selectedStaffIds.contains(
                                  staff.staffSeq,
                                ),
                                onChanged: (selected) => onStaffSelected(
                                  staff.staffSeq,
                                  selected ?? false,
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          _TextCell(
                            width: numberWidth,
                            text: '${index + 1}',
                            alignment: Alignment.center,
                          ),
                        ),
                        DataCell(
                          _TextCell(
                            width: nameWidth,
                            text: staff.name,
                            alignment: Alignment.center,
                          ),
                        ),
                        DataCell(
                          _TextCell(width: staffIdWidth, text: staff.staffId),
                        ),
                        DataCell(
                          _TextCell(
                            width: phoneWidth,
                            text: _formatPhoneNumber(staff.staffPhone),
                          ),
                        ),
                        DataCell(
                          _TextCell(
                            width: roleWidth,
                            text: staff.role,
                            alignment: Alignment.center,
                          ),
                        ),
                        DataCell(
                          _TextCell(width: emailWidth, text: staff.email),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.width, required this.label});

  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _TextCell extends StatelessWidget {
  const _TextCell({
    required this.width,
    required this.text,
    this.alignment = Alignment.centerLeft,
  });

  final double width;
  final String text;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: alignment,
        child: Text(text, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
