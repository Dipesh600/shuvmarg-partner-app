import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuvmarg_partner_app/domain/app_role.dart';
import 'package:shuvmarg_partner_app/features/entry/force_password/force_password_route.dart';
import 'package:shuvmarg_partner_app/features/entry/force_password/force_password_screen.dart';
import 'package:shuvmarg_partner_app/shared/session/session_response.dart';

void main() {
  test('password setup screen stays within the 250-line boundary', () {
    final lines = File(
      'lib/features/entry/force_password/force_password_screen.dart',
    ).readAsLinesSync().length;
    expect(lines, lessThanOrEqualTo(250));
  });

  test('forced-password response becomes the agent session', () {
    final result = sessionFromResponse(
      {
        'accessToken': 'access',
        'activeRole': 'agent',
        'user': {
          '_id': 'user-1',
          'name': 'Bijay',
          'phone': '9800000000',
          'roles': ['agent'],
        },
      },
      fallbackRole: AppRole.agent,
      refreshToken: 'refresh',
    );

    expect(result.valueOrNull?.activeRole, AppRole.agent);
    expect(result.valueOrNull?.accessToken, 'access');
    expect(result.valueOrNull?.refreshToken, 'refresh');
  });

  test('forced-password response fails without a real session token', () {
    final result = sessionFromResponse(
      const {'user': <String, dynamic>{}},
      fallbackRole: AppRole.agent,
      refreshToken: null,
    );
    expect(result.isErr, isTrue);
  });

  testWidgets('password setup explains exact backend rules', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ForcePasswordScreen(
            args: const ForcePasswordArgs(
              tempToken: 'temporary-token',
              role: AppRole.agent,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Choose your own password'), findsOneWidget);
    expect(find.textContaining('8 or more characters'), findsOneWidget);
    expect(find.textContaining('uppercase letter'), findsOneWidget);
    expect(find.textContaining('one number'), findsOneWidget);
  });

  testWidgets('missing secure handoff never renders a password form', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ForcePasswordScreen(args: null)),
      ),
    );

    expect(find.text('Start your sign-in again'), findsOneWidget);
    expect(find.text('New password'), findsNothing);
  });

  testWidgets('client rejects a mismatched confirmation before the network', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ForcePasswordScreen(
            args: const ForcePasswordArgs(
              tempToken: 'temporary-token',
              role: AppRole.agent,
            ),
          ),
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Password1');
    await tester.enterText(fields.at(1), 'Password2');
    await tester.tap(find.text('Save password and continue'));
    await tester.pump();

    expect(find.text('The passwords do not match.'), findsOneWidget);
  });
}
