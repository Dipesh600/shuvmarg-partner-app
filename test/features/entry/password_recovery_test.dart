import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';
import 'package:shuvmarg_partner_app/core/errors/backend_error_code.dart';
import 'package:shuvmarg_partner_app/core/errors/failure.dart';
import 'package:shuvmarg_partner_app/core/errors/result.dart';
import 'package:shuvmarg_partner_app/domain/app_role.dart';
import 'package:shuvmarg_partner_app/features/entry/password_recovery/password_recovery_repository.dart';
import 'package:shuvmarg_partner_app/features/entry/password_recovery/password_recovery_route.dart';
import 'package:shuvmarg_partner_app/features/entry/password_recovery/password_recovery_screen.dart';
import 'package:shuvmarg_partner_app/features/entry/password_recovery/recovery_completion_step.dart';

class _RecoveryGateway implements PasswordRecoveryGateway {
  _RecoveryGateway({this.requestResult = const Result.ok(null)});

  final Result<void> requestResult;
  final calls = <String>[];

  @override
  Future<Result<void>> requestCode(String phone, AppRole role) async {
    calls.add('request:${role.wire}:$phone');
    return requestResult;
  }

  @override
  Future<Result<void>> verifyCode(
    String phone,
    String otp,
    AppRole role,
  ) async {
    calls.add('verify:${role.wire}:$phone:$otp');
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> resendCode(String phone, AppRole role) async {
    calls.add('resend:${role.wire}:$phone');
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
    expect(find.textContaining('For your privacy'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(gateway.calls, ['request:agent:9800000000']);
    expect(find.text('Enter the 6-digit code'), findsOneWidget);
    expect(
      find.text('Check messages for a code at +977 98••••••00'),
      findsOneWidget,
    );
    expect(find.textContaining('OTP has been sent'), findsNothing);
    expect(find.textContaining('Sent by SMS'), findsNothing);
    expect(find.text('New password'), findsNothing);

    await tester.enterText(find.byType(Pinput), '123456');
    await tester.tap(find.text('Continue securely'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(gateway.calls, [
      'request:agent:9800000000',
      'verify:agent:9800000000:123456',
    ]);
    expect(find.text('Choose a new password'), findsOneWidget);
    expect(find.byType(Pinput), findsNothing);
  });

  testWidgets('driver recovery uses the driver account flow', (tester) async {
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
              role: AppRole.driver,
              phone: '9800000000',
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('phone on your driver account'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(gateway.calls, ['request:driver:9800000000']);
    expect(find.text('Enter the 6-digit code'), findsOneWidget);
  });

  testWidgets('non-driver phone stays on lookup and never shows OTP', (
    tester,
  ) async {
    final gateway = _RecoveryGateway(
      requestResult: const Result.err(
        NotFoundFailure(
          message: 'No Driver account was found for this phone number.',
          code: BackendErrorCode.driverAccountNotFound,
          statusCode: 404,
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          passwordRecoveryRepositoryProvider.overrideWithValue(gateway),
        ],
        child: const MaterialApp(
          home: PasswordRecoveryScreen(
            args: PasswordRecoveryArgs(
              role: AppRole.driver,
              phone: '9800000000',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.text('Enter the 6-digit code'), findsNothing);
    expect(
      find.text('No Driver account was found for this phone number.'),
      findsOneWidget,
    );
  });

  test('route handoff contains no OTP or password', () {
    final route = File(
      'lib/features/entry/password_recovery/password_recovery_route.dart',
    ).readAsStringSync();
    expect(route, isNot(contains('otp')));
    expect(route, isNot(contains('password')));
  });

  testWidgets('missing automatic session offers a direct sign-in handoff', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecoveryCompletionStep(onSignIn: () => pressed = true),
        ),
      ),
    );

    expect(find.text('Your password was saved'), findsOneWidget);
    expect(find.text('Enter the 6-digit code'), findsNothing);
    await tester.tap(find.text('Sign in with new password'));
    expect(pressed, isTrue);
  });
}
