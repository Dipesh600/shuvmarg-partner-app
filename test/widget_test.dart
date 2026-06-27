// Basic smoke test for Shuvmarg Partner App
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shuvmarg_partner_app/main.dart';

void main() {
  testWidgets('App starts without crash', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ShuvmargPartnerApp()),
    );
    // App initialized successfully — splash screen shows
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
