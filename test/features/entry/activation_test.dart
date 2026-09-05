import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';
import 'package:shuvmarg_partner_app/core/errors/backend_error_code.dart';
import 'package:shuvmarg_partner_app/core/errors/failure.dart';
import 'package:shuvmarg_partner_app/core/errors/result.dart';
import 'package:shuvmarg_partner_app/domain/app_role.dart';
import 'package:shuvmarg_partner_app/features/entry/activation/activation_repository.dart';
import 'package:shuvmarg_partner_app/features/entry/activation/activation_route.dart';
import 'package:shuvmarg_partner_app/features/entry/activation/activation_screen.dart';
import 'package:shuvmarg_partner_app/features/entry/sign_in_screen.dart';

class _OtpGateway implements ActivationGateway {
  _OtpGateway({
    this.result = const Result.ok('5 minutes'),
    this.expectedRole = AppRole.agent,
  });

  final Result<String> result;
  final AppRole expectedRole;
  int calls = 0;

  @override
  Future<Result<String>> sendOtp(String phone, AppRole role) async {
    calls += 1;
    expect(phone, '9800000000');
    expect(role, expectedRole);
    return result;
  }
}

void main() {
  test('activation production files stay within 250 lines', () {
    for (final file in Directory(
      'lib/features/entry/activation',
    ).listSync().whereType<File>()) {
      expect(
        file.readAsLinesSync().length,
        lessThanOrEqualTo(250),
        reason: file.path,
      );
    }
  });

  testWidgets(
    'activation separates OTP from password and pins password rules',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gateway = _OtpGateway();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [activationRepositoryProvider.overrideWithValue(gateway)],
          child: const MaterialApp(
            home: ActivationScreen(
              args: ActivationArgs(phone: '9800000000', role: AppRole.agent),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(gateway.calls, 0);
      expect(find.text('Set up your account'), findsOneWidget);
      expect(find.text('Enter the 6-digit code'), findsNothing);
      await tester.tap(find.text('Check invitation and send code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(gateway.calls, 1);
      expect(find.text('Enter the 6-digit code'), findsOneWidget);
      expect(find.textContaining('+977 98••••••00'), findsOneWidget);
      expect(find.textContaining('Code expires in 5 minutes'), findsOneWidget);
      expect(find.text('New password'), findsNothing);

      await tester.enterText(find.byType(Pinput), '123456');
      await tester.tap(find.text('Continue securely'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Enter the 6-digit code'), findsNothing);
      expect(find.text('Create your password'), findsOneWidget);
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), 'password1');
      await tester.enterText(fields.at(1), 'password1');
      await tester.tap(find.text('Activate my account'));
      await tester.pump();

      expect(find.text('Add at least one uppercase letter.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('activation steps do not expose each other or persist the OTP', () {
    final otpStep = File(
      'lib/features/entry/activation/activation_otp_step.dart',
    ).readAsStringSync();
    final passwordStep = File(
      'lib/features/entry/activation/activation_password_step.dart',
    ).readAsStringSync();
    final route = File(
      'lib/features/entry/activation/activation_route.dart',
    ).readAsStringSync();

    expect(otpStep, isNot(contains('New password')));
    expect(passwordStep, isNot(contains('Pinput')));
    expect(route, isNot(contains('otp')));
    expect(route, isNot(contains('password')));
  });

  test('sign in exposes invited-account setup only for crew roles', () {
    final signIn = File(
      'lib/features/entry/sign_in_screen.dart',
    ).readAsStringSync();

    expect(signIn, contains('Set up invited account'));
    expect(signIn, contains('if (role != AppRole.agent)'));
    expect(signIn, contains('AppRoutes.activateAccount'));
    expect(signIn, contains('ActivationArgs(role: role)'));
    expect(signIn, isNot(contains('Enter the invited 10-digit mobile number')));
    expect(signIn, isNot(contains('enter ACTIVATE')));
  });

  testWidgets('agent login hides crew invitation setup', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SignInScreen(roleWire: 'agent')),
      ),
    );
    expect(find.text('Set up invited account'), findsNothing);
    expect(find.text('Forgot password?'), findsOneWidget);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SignInScreen(roleWire: 'driver')),
      ),
    );
    expect(find.text('Set up invited account'), findsOneWidget);
  });

  testWidgets('no invitation stays on phone entry and never claims SMS sent', (
    tester,
  ) async {
    final gateway = _OtpGateway(
      expectedRole: AppRole.driver,
      result: const Result.err(
        NotFoundFailure(
          message:
              'No pending driver invitation was found for this phone number.',
          code: BackendErrorCode.invitationNotFound,
          statusCode: 404,
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [activationRepositoryProvider.overrideWithValue(gateway)],
        child: const MaterialApp(
          home: ActivationScreen(
            args: ActivationArgs(phone: '9800000000', role: AppRole.driver),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Check invitation and send code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Set up your account'), findsOneWidget);
    expect(find.text('Enter the 6-digit code'), findsNothing);
    expect(find.textContaining('Sent by SMS'), findsNothing);
    expect(find.textContaining('No pending driver invitation'), findsOneWidget);
  });

  testWidgets('active account is directed to sign in without showing OTP', (
    tester,
  ) async {
    final gateway = _OtpGateway(
      expectedRole: AppRole.driver,
      result: const Result.err(
        UnknownFailure(
          message:
              'This driver account is already active. Sign in with your password.',
          code: BackendErrorCode.accountAlreadyActive,
          statusCode: 409,
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [activationRepositoryProvider.overrideWithValue(gateway)],
        child: const MaterialApp(
          home: ActivationScreen(
            args: ActivationArgs(phone: '9800000000', role: AppRole.driver),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Check invitation and send code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Go to sign in'), findsOneWidget);
    expect(find.text('Enter the 6-digit code'), findsNothing);
    expect(find.textContaining('already active'), findsOneWidget);
  });

  testWidgets('missing in-memory activation handoff fails closed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ActivationScreen(args: null)),
      ),
    );

    expect(find.text('Return to sign in'), findsOneWidget);
    expect(find.text('SMS code'), findsNothing);
  });
}
