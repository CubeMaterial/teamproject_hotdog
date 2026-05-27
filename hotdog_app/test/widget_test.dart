import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hotdog_app/features/admin/auth/domain/entities/auth_session.dart';
import 'package:hotdog_app/features/admin/auth/domain/repositories/auth_repository.dart';
import 'package:hotdog_app/features/admin/auth/presentation/providers/auth_providers.dart';
import 'package:hotdog_app/features/admin/auth/temp/temporary_admin_credentials.dart';
import 'package:hotdog_app/main.dart';

void main() {
  testWidgets('Admin dashboard smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(find.text('로그인'), findsAtLeastNWidgets(1));

    await tester.enterText(find.byType(EditableText).first, '1004');
    await tester.enterText(
      find.byType(EditableText).last,
      TemporaryAdminCredentials.password,
    );
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('대시보드 개요'), findsOneWidget);

    await tester.tap(find.text('주문관리'));
    await tester.pump();
    await tester.tap(find.text('환불'));
    await tester.pump();

    expect(find.text('환불 관리'), findsOneWidget);

    await tester.tap(find.text('대시보드'));
    await tester.pump();

    expect(find.text('대시보드 개요'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  AuthSession? _session;

  @override
  Future<AuthSession?> restoreSession() async => _session;

  @override
  Future<AuthSession> login({
    required String loginId,
    required String password,
    required bool rememberMe,
  }) async {
    _session = AuthSession(
      staffSeq: loginId.split('@').first,
      staffEmail: loginId,
      rememberMe: rememberMe,
      createdAt: DateTime(2026, 5, 7),
    );
    return _session!;
  }

  @override
  Future<void> logout() async {
    _session = null;
  }
}
