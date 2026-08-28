import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('invited agent receives one OTP and exact password rules', (
    tester,
  ) async {
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
    await tester.pumpAndSettle();

    expect(gateway.calls, 1);
    expect(find.textContaining('+977 9800000000'), findsOneWidget);
    expect(find.textContaining('Valid for 5 minutes'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '123456');
    await tester.enterText(fields.at(1), 'password1');
    await tester.enterText(fields.at(2), 'password1');
    await tester.tap(find.text('Activate and continue'));
    await tester.pump();

    expect(find.text('Add at least one uppercase letter.'), findsOneWidget);
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
