import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

import '../../../../domain/entities/staff.dart';
import '../../../view_models/staff_view_model.dart';
import '../../../widgets/dashboard_paginated_section.dart';
import '../../../widgets/dashboard_tab_header.dart';
import 'widgets/staff_filter_bar.dart';
import 'widgets/staff_form_dialog.dart';
import 'widgets/staff_table.dart';

class StaffManageTab extends StatefulWidget {
  const StaffManageTab({
    super.key,
    required this.viewModel,
    required this.canRegister,
    required this.canDelete,
  });

  final StaffViewModel viewModel;
  final bool canRegister;
  final bool canDelete;

  @override
  State<StaffManageTab> createState() => _StaffManageTabState();
}

class _StaffManageTabState extends State<StaffManageTab> {
  final Set<String> _selectedStaffSeqs = {};
  String _selectedRole = '전체';
  String _nameQuery = '';
  bool _isDeleting = false;

  Future<void> _openStaffForm() async {
    final formData = await showDialog<StaffFormData>(
      context: context,
      builder: (_) => const StaffFormDialog(),
    );

    if (!mounted || formData == null) {
      return;
    }

    try {
      final result = await widget.viewModel.createStaff(
        staffName: formData.staffName,
        staffId: formData.staffId,
        staffPhone: formData.staffPhone,
        staffLevel: formData.staffLevel,
      );

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.emailSent
                ? '직원 등록과 안내메일 발송이 완료되었습니다.'
                : '직원 등록이 완료되었습니다. ${result.emailWarning}',
          ),
        ),
      );

      if (!result.emailSent && result.emailBody.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (_) => _EmailPreviewDialog(
            subject: result.emailSubject,
            body: result.emailBody,
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('직원 등록 실패: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStaffs = widget.viewModel.staffs.where((staff) {
      final matchesRole = _selectedRole == '전체' || staff.role == _selectedRole;
      final matchesName = _nameQuery.isEmpty || staff.name.contains(_nameQuery);

      return matchesRole && matchesName;
    }).toList();
    _removeDeletedSelections(widget.viewModel.staffs);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        DashboardTabHeader(
          title: '직원 관리',
          subtitle: '관리자와 운영 직원을 관리합니다.',
          actions: [
            if (widget.canDelete)
              _HeaderActionButton(
                onPressed: _selectedStaffSeqs.isEmpty || _isDeleting
                    ? null
                    : _deleteSelectedStaffs,
                icon: const Icon(Icons.delete_outline),
                label: '삭제',
              ),
            _HeaderActionButton(
              onPressed: widget.canRegister ? _openStaffForm : null,
              icon: const Icon(Icons.person_add_alt),
              label: '직원 등록',
            ),
          ],
        ),
        const SizedBox(height: 16),
        StaffFilterBar(
          selectedRole: _selectedRole,
          onRoleChanged: (role) {
            if (role == null) {
              return;
            }

            setState(() => _selectedRole = role);
          },
          onNameChanged: (value) {
            setState(() => _nameQuery = value.trim());
          },
        ),
        const SizedBox(height: 16),
        DashboardPaginatedSection(
          items: filteredStaffs,
          tableBuilder: (staffs) => StaffTable(
            staffs: staffs,
            selectedStaffIds: _selectedStaffSeqs,
            onStaffSelected: _setStaffSelected,
            onAllStaffSelected: (selected) =>
                _setVisibleStaffsSelected(staffs, selected),
          ),
        ),
      ],
    );
  }

  void _setStaffSelected(String staffSeq, bool selected) {
    setState(() {
      if (selected) {
        _selectedStaffSeqs.add(staffSeq);
      } else {
        _selectedStaffSeqs.remove(staffSeq);
      }
    });
  }

  void _setVisibleStaffsSelected(List<Staff> staffs, bool selected) {
    setState(() {
      for (final staff in staffs) {
        if (selected) {
          _selectedStaffSeqs.add(staff.staffSeq);
        } else {
          _selectedStaffSeqs.remove(staff.staffSeq);
        }
      }
    });
  }

  Future<void> _deleteSelectedStaffs() async {
    if (_selectedStaffSeqs.isEmpty) {
      return;
    }

    final confirmed = await _showDeleteConfirmDialog();

    if (!confirmed) {
      return;
    }

    final ids = _selectedStaffSeqs.toSet();
    setState(() => _isDeleting = true);

    try {
      await widget.viewModel.deleteStaffs(ids);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedStaffSeqs.removeAll(ids);
        _isDeleting = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('직원 삭제 실패: $error')));
    }
  }

  void _removeDeletedSelections(List<Staff> staffs) {
    final staffSeqs = staffs.map((staff) => staff.staffSeq).toSet();
    _selectedStaffSeqs.removeWhere((staffSeq) => !staffSeqs.contains(staffSeq));
  }

  Future<bool> _showDeleteConfirmDialog() async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '취소',
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return const _StaffDeleteConfirmDialog();
      },
    );

    return confirmed ?? false;
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 45,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.deepOrange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.deepOrange.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: const IconThemeData(size: 22, color: Colors.white),
              child: icon,
            ),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffDeleteConfirmDialog extends StatelessWidget {
  const _StaffDeleteConfirmDialog();

  static const _red = Color(0xFFF50000);
  static const _buttonGray = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              color: _red,
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: const Text(
                '삭제 하시겠습니까?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(
                '삭제한 직원 정보는\n되돌릴 수 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 10, 40, 24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          backgroundColor: _buttonGray,
                          foregroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: const Text('취소', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: const Text('확인', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailPreviewDialog extends StatelessWidget {
  const _EmailPreviewDialog({required this.subject, required this.body});

  final String subject;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: const Text('안내메일 미리보기'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            SelectableText(body),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
