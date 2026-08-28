import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuvmarg_partner_app/features/agent/assignments/data/agent_assignment.dart';
import 'package:shuvmarg_partner_app/features/agent/assignments/widgets/assignment_card.dart';

void main() {
  testWidgets('invite names the operator, terms, expiry and both decisions', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_card(_assignment())));

    expect(find.text('Dai Bhai Travels'), findsOneWidget);
    expect(find.text('Invited you to sell tickets'), findsOneWidget);
    expect(find.text('All buses from this operator'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('5% of each booking'), findsOneWidget);
    expect(find.textContaining('Accept before'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });

  testWidgets('accepted access never claims selling readiness before KYC', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _card(
          _assignment(status: AgentAssignmentStatus.active),
          kycCleared: false,
        ),
      ),
    );

    expect(find.text('Verify first'), findsOneWidget);
    expect(
      find.text(
        'Access accepted. Complete verification before selling tickets.',
      ),
      findsOneWidget,
    );
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Decline'), findsNothing);
  });

  testWidgets('only active plus cleared KYC says ready to sell', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _card(
          _assignment(status: AgentAssignmentStatus.active),
          kycCleared: true,
        ),
      ),
    );

    expect(find.text('Ready to sell'), findsOneWidget);
    expect(
      find.text('You are cleared to sell tickets for this operator.'),
      findsOneWidget,
    );
  });

  testWidgets('verified access stays limited without cash permission', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _card(
          _assignment(status: AgentAssignmentStatus.active, canSellCash: false),
          kycCleared: true,
        ),
      ),
    );

    expect(find.text('Ready to sell'), findsNothing);
    expect(find.text('Access limited'), findsOneWidget);
    expect(
      find.text('This operator has not enabled cash ticket sales for you.'),
      findsOneWidget,
    );
  });
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget _card(AgentAssignment assignment, {bool? kycCleared}) {
  return SingleChildScrollView(
    child: AssignmentCard(
      assignment: assignment,
      kycCleared: kycCleared,
      busy: false,
      actionsLocked: false,
      onAccept: () {},
      onDecline: () {},
    ),
  );
}

AgentAssignment _assignment({
  AgentAssignmentStatus status = AgentAssignmentStatus.invited,
  bool canSellCash = true,
}) {
  return AgentAssignment(
    id: '64c000000000000000000001',
    status: status,
    brandId: '64c000000000000000000002',
    brandName: 'Dai Bhai Travels',
    accessScope: 'ALL_BUSES',
    permissions: AssignmentPermissions(
      canSellCash: canSellCash,
      canSellOnline: false,
      canCancel: false,
      cancelWindowMins: 0,
      maxSeatsPerBooking: 4,
      maxDiscountPct: 0,
    ),
    commission: const AssignmentCommission(mode: 'PERCENT', value: 5),
    invitedAt: DateTime(2026, 8, 28),
    expiresAt: DateTime(2026, 9, 4),
  );
}
