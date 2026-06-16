import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

class StaffFormDialog extends StatefulWidget {
  const StaffFormDialog({super.key});

  @override
  State<StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<StaffFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _staffIdController = TextEditingController();
  final _phoneController = TextEditingController();
  int _selectedStaffLevel = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _staffIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '직원 등록',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: const Color(0xFF333333),
                        iconSize: 30,
                        tooltip: '닫기',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Divider(height: 1, color: AppColors.border),
                  _FormRow(
                    label: '직원 이름',
                    child: TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('직원 이름'),
                      validator: (value) => _required(value, '직원 이름을 등록해주세요.'),
                    ),
                  ),
                  _FormRow(
                    label: '사번',
                    child: TextFormField(
                      controller: _staffIdController,
                      decoration: _inputDecoration('사번'),
                      validator: (value) => _required(value, '사번을 등록해주세요.'),
                    ),
                  ),
                  _FormRow(
                    label: '직원 연락처',
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_PhoneNumberInputFormatter()],
                      decoration: _inputDecoration('000-0000-0000'),
                      validator: _validatePhone,
                    ),
                  ),
                  _FormRow(
                    label: '직급',
                    child: RadioGroup<int>(
                      groupValue: _selectedStaffLevel,
                      onChanged: _changeRole,
                      child: const Row(
                        children: [
                          _RoleRadio(value: 1, label: '사원'),
                          _RoleRadio(value: 2, label: '주임'),
                          _RoleRadio(value: 3, label: '대리'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('등록'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: const OutlineInputBorder(),
      isDense: true,
      errorStyle: const TextStyle(color: Colors.red, fontSize: 10, height: 1.1),
    );
  }

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final requiredMessage = _required(value, '직원 연락처를 등록해주세요.');

    if (requiredMessage != null) {
      return requiredMessage;
    }

    final digits = _digitsOnly(value ?? '');

    if (digits.length != 10 && digits.length != 11) {
      return '전화번호는 10자리 또는 11자리 숫자여야 합니다.';
    }

    return null;
  }

  void _changeRole(int? value) {
    if (value == null) {
      return;
    }

    setState(() => _selectedStaffLevel = value);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      StaffFormData(
        staffName: _nameController.text.trim(),
        staffId: _staffIdController.text.trim(),
        staffPhone: _formatPhoneNumber(_phoneController.text),
        staffLevel: _selectedStaffLevel,
      ),
    );
  }

  String _formatPhoneNumber(String value) {
    final digits = _digitsOnly(value);

    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }

    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }

    return value.trim();
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }
}

class _PhoneNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitedDigits = digits.length > 11 ? digits.substring(0, 11) : digits;
    final formatted = _format(limitedDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    if (digits.length <= 3) {
      return digits;
    }

    if (digits.length <= 6) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }

    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }

    return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 150,
              color: AppColors.beige,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StaffFormData {
  const StaffFormData({
    required this.staffName,
    required this.staffId,
    required this.staffPhone,
    required this.staffLevel,
  });

  final String staffName;
  final String staffId;
  final String staffPhone;
  final int staffLevel;
}

class _RoleRadio extends StatelessWidget {
  const _RoleRadio({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => RadioGroup.maybeOf<int>(context)?.onChanged(value),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<int>(
              value: value,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}
