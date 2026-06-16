import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/admin/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'features/admin/dashboard/presentation/pages/admin_login_page.dart';
import 'features/admin/auth/presentation/providers/auth_providers.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authViewModel = ref.watch(authViewModelProvider);

    return MaterialApp(
      title: 'Hotdog Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: authViewModel.isAuthenticated
          ? AdminDashboardPage(onLogout: authViewModel.logout)
          : const AdminLoginPage(),
    );
  }
}
