import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _staffNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _staffNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 820;

                    final form = Padding(
                      padding: EdgeInsets.all(wide ? 48 : 28),
                      child: _LoginForm(
                        formKey: _formKey,
                        staffNumberController: _staffNumberController,
                        passwordController: _passwordController,
                        obscurePassword: _obscurePassword,
                        rememberMe: _rememberMe,
                        errorMessage: authViewModel.errorMessage,
                        isLoading: authViewModel.isLoading,
                        onTogglePassword: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        onRememberChanged: (value) =>
                            setState(() => _rememberMe = value ?? false),
                        onSubmit: _submit,
                      ),
                    );

                    if (!wide) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BrandPanel(wide: wide),
                          form,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(flex: 5, child: _BrandPanel(wide: wide)),
                        Expanded(flex: 4, child: form),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final loggedIn = await ref
        .read(authViewModelProvider)
        .login(
          loginId: _staffNumberController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );

    if (!mounted || loggedIn) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(authViewModelProvider).errorMessage ?? '로그인에 실패했습니다.',
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: wide ? 560 : 260),
      padding: EdgeInsets.all(wide ? 48 : 30),
      decoration: BoxDecoration(
        color: AppColors.deepOrange,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(28),
          topRight: Radius.circular(wide ? 0 : 28),
          bottomLeft: Radius.circular(wide ? 28 : 0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'images/hotdog_icon.png',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              const Text(
                'HOTDOG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '직원 전용 포털',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '주문, 재고, 직원, 커뮤니티 운영을 한 곳에서 관리하세요.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                  height: 1.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Text(
              '직원 계정으로 로그인',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.staffNumberController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.errorMessage,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onRememberChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController staffNumberController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final String? errorMessage;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '로그인',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '회사 계정 아이디와 비밀번호를 입력해 주세요.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          _CompanyAccountFields(staffNumberController: staffNumberController),
          const SizedBox(height: 18),
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!isLoading) {
                onSubmit();
              }
            },
            decoration: InputDecoration(
              labelText: '비밀번호',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                tooltip: obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if ((value ?? '').length < 4) {
                return '비밀번호를 4자 이상 입력해 주세요.';
              }
              return null;
            },
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 12),
          CheckboxListTile(
            value: rememberMe,
            onChanged: onRememberChanged,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('로그인 상태 유지'),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: isLoading ? null : onSubmit,
            icon: isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: Text(isLoading ? '확인 중' : '로그인'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: AppColors.deepOrange,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyAccountFields extends StatelessWidget {
  const _CompanyAccountFields({required this.staffNumberController});

  final TextEditingController staffNumberController;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: TextFormField(
            controller: staffNumberController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '아이디를 입력하세요.',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return '아이디를 입력해 주세요.';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: TextFormField(
            initialValue: 'hotdog.com',
            readOnly: true,
            decoration: const InputDecoration(
              labelText: '회사 계정 메일',
              prefixIcon: Icon(Icons.alternate_email),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
