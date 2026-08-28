import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';
import 'package:shuvmarg_partner_app/core/errors/result.dart';
import 'package:shuvmarg_partner_app/domain/app_role.dart';
import 'package:shuvmarg_partner_app/features/entry/activation/activation_repository.dart';
import 'package:shuvmarg_partner_app/features/entry/activation/activation_route.dart';
import 'package:shuvmarg_partner_app/features/entry/activation/activation_screen.dart';

class _OtpGateway implements ActivationGateway {
  int calls = 0;

  @override
  Future<Result<String>> sendOtp(String phone, AppRole role) async {
    calls += 1;
    expect(phone, '9800000000');
    expect(role, AppRole.agent);
    return const Result.ok('5 minutes');
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
