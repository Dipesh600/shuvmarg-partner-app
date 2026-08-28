import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';
import 'package:shuvmarg_partner_app/core/errors/result.dart';
import 'package:shuvmarg_partner_app/domain/app_role.dart';
import 'package:shuvmarg_partner_app/features/entry/password_recovery/password_recovery_repository.dart';
import 'package:shuvmarg_partner_app/features/entry/password_recovery/password_recovery_route.dart';
import 'package:shuvmarg_partner_app/features/entry/password_recovery/password_recovery_screen.dart';

class _RecoveryGateway implements PasswordRecoveryGateway {
  final calls = <String>[];

  @override
  Future<Result<void>> requestCode(String phone) async {
    calls.add('request:$phone');
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> verifyCode(String phone, String otp) async {
    calls.add('verify:$phone:$otp');
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> resendCode(String phone) async {
    calls.add('resend:$phone');
    return const Result.ok(null);
  }
}

void main() {
  test('password recovery production files stay within 250 lines', () {
    for (final file in Directory(
      'lib/features/entry/password_recovery',
    ).listSync().whereType<File>()) {
      expect(
        file.readAsLinesSync().length,
        lessThanOrEqualTo(250),
        reason: file.path,
      );
    }
  });

  testWidgets('recovery verifies the phone before showing password fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = _RecoveryGateway();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          passwordRecoveryRepositoryProvider.overrideWithValue(gateway),
        ],
        child: const MaterialApp(
          home: PasswordRecoveryScreen(
            args: PasswordRecoveryArgs(
              role: AppRole.agent,
              phone: '9800000000',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.text('New password'), findsNothing);
    await tester.tap(find.text('Send verification code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(gateway.calls, ['request:9800000000']);
    expect(find.text('Enter the 6-digit code'), findsOneWidget);
    expect(find.text('New password'), findsNothing);

    await tester.enterText(find.byType(Pinput), '123456');
    await tester.tap(find.text('Continue securely'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(gateway.calls, ['request:9800000000', 'verify:9800000000:123456']);
    expect(find.text('Choose a new password'), findsOneWidget);
    expect(find.byType(Pinput), findsNothing);
  });

  test('route handoff contains no OTP or password', () {
    final route = File(
      'lib/features/entry/password_recovery/password_recovery_route.dart',
    ).readAsStringSync();
    expect(route, isNot(contains('otp')));
    expect(route, isNot(contains('password')));
  });
}
