import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

import '../../../../domain/entities/staff.dart';
import '../../../view_models/staff_view_model.dart';
import '../../../widgets/dashboard_tab_header.dart';

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({
    super.key,
    required this.staff,
    required this.staffViewModel,
    required this.onLogout,
  });

  final Staff? staff;
  final StaffViewModel staffViewModel;
  final VoidCallback onLogout;

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final TextEditingController _phoneController;
  bool _isSaving = false;
  bool _isVerifyingPassword = false;
  bool _isPasswordVerified = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: _formatPhoneNumber(widget.staff?.staffPhone ?? ''),
    );
  }

  @override
  void didUpdateWidget(covariant AdminProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.staff?.staffSeq != widget.staff?.staffSeq ||
        oldWidget.staff?.staffPhone != widget.staff?.staffPhone) {
      _phoneController.text = _formatPhoneNumber(
        widget.staff?.staffPhone ?? '',
      );
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staff = widget.staff;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardTabHeader(
            title: '내 정보 수정',
            subtitle: '로그인한 관리자 계정 정보를 확인하고 수정합니다.',
            actions: [
              OutlinedButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              SizedBox(
                width: 280,
                child: DecoratedBox(
                  decoration: _panelDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.beige,
                          child: Icon(
                            Icons.person,
                            size: 46,
                            color: AppColors.deepOrange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          staff?.name ?? '로그인 직원',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          staff?.role ?? '직급',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.neutral),
                        ),
                        const SizedBox(height: 18),
                        _InfoRow(label: '직원번호', value: staff?.id ?? '-'),
                        _InfoRow(label: '직원명', value: staff?.staffName ?? '-'),
                        _InfoRow(label: '직급', value: staff?.role ?? '-'),
                      ],
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: DecoratedBox(
                  decoration: _panelDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '기본 정보',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 18),
                          _ProfileInfoField(
                            label: '직원명',
                            value: staff?.staffName ?? '-',
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _PasswordField(
                                  controller: _currentPasswordController,
                                  label: '현재 비밀번호',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscureCurrentPassword,
                                  enabled:
                                      staff != null &&
                                      !_isSaving &&
                                      !_isVerifyingPassword,
                                  onChanged: _handleCurrentPasswordChanged,
                                  onToggleVisibility: () => setState(
                                    () => _obscureCurrentPassword =
                                        !_obscureCurrentPassword,
                                  ),
                                  validator: _validateCurrentPassword,
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 132,
                                height: 56,
                                child: FilledButton(
                                  onPressed: _canVerifyCurrentPassword
                                      ? _verifyCurrentPassword
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.deepOrange,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: _isPasswordVerified
                                        ? AppColors.deepOrange.withValues(
                                            alpha: 0.72,
                                          )
                                        : null,
                                    disabledForegroundColor: _isPasswordVerified
                                        ? Colors.white
                                        : null,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    _isVerifyingPassword
                                        ? '확인 중'
                                        : _isPasswordVerified
                                        ? '확인 완료'
                                        : '비밀번호 확인',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isPasswordVerified) ...[
                            const SizedBox(height: 8),
                            const Text(
                              '현재 비밀번호가 확인되었습니다.',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          _PasswordField(
                            controller: _newPasswordController,
                            label: '새 비밀번호',
                            icon: Icons.lock_reset,
                            obscureText: _obscureNewPassword,
                            enabled:
                                staff != null &&
                                !_isSaving &&
                                _isPasswordVerified,
                            onToggleVisibility: () => setState(
                              () => _obscureNewPassword = !_obscureNewPassword,
                            ),
                            validator: _validateNewPassword,
                          ),
                          const SizedBox(height: 14),
                          _PasswordField(
                            controller: _confirmPasswordController,
                            label: '비밀번호 확인',
                            icon: Icons.verified_user_outlined,
                            obscureText: _obscureConfirmPassword,
                            enabled:
                                staff != null &&
                                !_isSaving &&
                                _isPasswordVerified,
                            onToggleVisibility: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                            validator: _validateConfirmPassword,
                          ),
                          const SizedBox(height: 14),
                          _ProfileInfoField(
                            label: '직급',
                            value: staff?.role ?? '-',
                            icon: Icons.work_outline,
                          ),
                          const SizedBox(height: 14),
                          _ProfileInfoField(
                            label: '이메일',
                            value: staff?.email ?? '-',
                            icon: Icons.mail_outline,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [_PhoneNumberInputFormatter()],
                            decoration: const InputDecoration(
                              labelText: '직원 연락처',
                              prefixIcon: Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: _validatePhone,
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: staff == null || _isSaving
                                  ? null
                                  : _saveProfile,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(_isSaving ? '저장 중' : '수정'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.deepOrange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final staff = widget.staff;
    if (staff == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final shouldUpdatePassword = _shouldUpdatePassword;
      final formattedPhone = _formatPhoneNumber(_phoneController.text);
      final shouldUpdatePhone =
          formattedPhone != _formatPhoneNumber(staff.staffPhone);

      if (shouldUpdatePassword) {
        await widget.staffViewModel.updateStaffPassword(
          staffSeq: staff.staffSeq,
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );
      }

      if (shouldUpdatePhone) {
        await widget.staffViewModel.updateStaffPhone(
          staffSeq: staff.staffSeq,
          staffPhone: formattedPhone,
        );
      }

      if (!mounted) {
        return;
      }

      if (shouldUpdatePassword) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _isPasswordVerified = false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_savedMessage(shouldUpdatePhone, shouldUpdatePassword)),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('내 정보 저장 실패: ${_errorMessage(error)}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool get _canVerifyCurrentPassword {
    return widget.staff != null &&
        !_isSaving &&
        !_isVerifyingPassword &&
        !_isPasswordVerified &&
        _currentPasswordController.text.isNotEmpty;
  }

  bool get _shouldUpdatePassword {
    return _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;
  }

  String _savedMessage(bool phoneChanged, bool passwordChanged) {
    if (phoneChanged && passwordChanged) {
      return '내 정보와 비밀번호가 저장되었습니다.';
    }

    if (passwordChanged) {
      return '비밀번호가 저장되었습니다.';
    }

    if (phoneChanged) {
      return '내 정보가 저장되었습니다.';
    }

    return '변경된 내용이 없습니다.';
  }

  void _handleCurrentPasswordChanged(String value) {
    setState(() {
      if (_isPasswordVerified) {
        _isPasswordVerified = false;
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    });
  }

  Future<void> _verifyCurrentPassword() async {
    final staff = widget.staff;
    if (staff == null || _currentPasswordController.text.isEmpty) {
      return;
    }

    setState(() => _isVerifyingPassword = true);

    try {
      await widget.staffViewModel.verifyStaffPassword(
        staffSeq: staff.staffSeq,
        currentPassword: _currentPasswordController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isPasswordVerified = true;
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('현재 비밀번호가 확인되었습니다.')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPasswordVerified = false;
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호 확인 실패: ${_errorMessage(error)}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifyingPassword = false);
      }
    }
  }

  String? _validateCurrentPassword(String? value) {
    if (!_shouldUpdatePassword) {
      return null;
    }

    if (!_isPasswordVerified) {
      return '현재 비밀번호 확인을 완료해 주세요.';
    }

    return null;
  }

  String? _validateNewPassword(String? value) {
    if (!_shouldUpdatePassword) {
      return null;
    }

    if (!_isPasswordVerified) {
      return '현재 비밀번호 확인을 먼저 완료해 주세요.';
    }

    if (value == null || value.isEmpty) {
      return '새 비밀번호를 입력해 주세요.';
    }

    if (value.length < 4) {
      return '새 비밀번호는 4자 이상 입력해 주세요.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_shouldUpdatePassword) {
      return null;
    }

    if (!_isPasswordVerified) {
      return '현재 비밀번호 확인을 먼저 완료해 주세요.';
    }

    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해 주세요.';
    }

    if (value != _newPasswordController.text) {
      return '새 비밀번호와 일치하지 않습니다.';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final digits = _digitsOnly(value ?? '');

    if (digits.isEmpty) {
      return '직원 연락처를 입력해 주세요.';
    }

    if (digits.length != 10 && digits.length != 11) {
      return '전화번호는 10자리 또는 11자리 숫자여야 합니다.';
    }

    return null;
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

  String _errorMessage(Object error) {
    final message = '$error'.replaceFirst('Exception: ', '');
    final detailIndex = message.lastIndexOf(': ');

    if (detailIndex == -1 || detailIndex + 2 >= message.length) {
      return message;
    }

    return message.substring(detailIndex + 2);
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.obscureText,
    required this.enabled,
    required this.onToggleVisibility,
    required this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final bool enabled;
  final VoidCallback onToggleVisibility;
  final String? Function(String?) validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          onPressed: enabled ? onToggleVisibility : null,
          tooltip: obscureText ? '비밀번호 보기' : '비밀번호 숨기기',
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
        ),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}

class _ProfileInfoField extends StatelessWidget {
  const _ProfileInfoField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.neutral)),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
