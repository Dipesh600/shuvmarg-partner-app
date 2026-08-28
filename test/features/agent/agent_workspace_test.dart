import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuvmarg_partner_app/domain/agent_identity.dart';
import 'package:shuvmarg_partner_app/domain/app_role.dart';
import 'package:shuvmarg_partner_app/domain/session.dart';
import 'package:shuvmarg_partner_app/features/agent/agent_home_screen.dart';
import 'package:shuvmarg_partner_app/features/agent/assignments/state/agent_assignments_controller.dart';
import 'package:shuvmarg_partner_app/features/agent/identity/agent_identity_controller.dart';
import 'package:shuvmarg_partner_app/features/agent/workspace/agent_workspace_kind.dart';
import 'package:shuvmarg_partner_app/shared/session/session_controller.dart';
import 'package:shuvmarg_partner_app/shared/session/session_providers.dart';
import 'package:shuvmarg_partner_app/shared/session/session_state.dart';
import 'package:shuvmarg_partner_app/shared/state/view_state.dart';

const _user = AuthenticatedUser(
  id: 'agent-1',
  name: 'Bijay Chaudhary',
  phone: '9800000000',
  roles: ['agent'],
  isVerified: true,
);

class _SignedInController extends SessionController {
  @override
  SessionState build() => const SessionSignedIn(
    session: Session(
      accessToken: 'access',
      activeRole: AppRole.agent,
      user: _user,
    ),
  );
}

class _IdentityController extends AgentIdentityController {
  _IdentityController(this.scope);

  final AgentScope? scope;

  @override
  ViewState<AgentIdentityView> build() => ViewState.data(
    AgentIdentityView(
      identity: AgentIdentity(
        agentCode: 'SM-AG-TEST',
        legacyAgentId: null,
        scope: scope,
        outletType: AgentOutletType.ticketCounter,
        kycStatus: null,
        kycStatusLabel: 'Phone verified',
        kycCleared: true,
        createdByOperator: scope == AgentScope.operatorOwned,
      ),
    ),
  );
}

class _AssignmentsController extends AgentAssignmentsController {
  @override
  ViewState<AgentAssignmentsView> build() => const ViewState.empty();
}

void main() {
  test('backend scope resolves to one explicit agent workspace', () {
    expect(
      workspaceKindForScope(AgentScope.operatorOwned),
      AgentWorkspaceKind.operatorOwned,
    );
    expect(
      workspaceKindForScope(AgentScope.platform),
      AgentWorkspaceKind.platform,
    );
  });

  test('missing scope fails closed instead of choosing a workspace', () {
    expect(workspaceKindForScope(null), AgentWorkspaceKind.unsupported);
  });

  testWidgets('operator account renders only the operator workspace', (
    tester,
  ) async {
    await _pumpWorkspace(tester, AgentScope.operatorOwned);

    expect(find.text('Your ticket counter'), findsOneWidget);
    expect(find.text('Your agent business'), findsNothing);
    expect(find.text('Platform agent'), findsNothing);
  });

  testWidgets('platform account renders only the platform workspace', (
    tester,
  ) async {
    await _pumpWorkspace(tester, AgentScope.platform);

    expect(find.text('Your agent business'), findsOneWidget);
    expect(find.text('Your ticket counter'), findsNothing);
    expect(find.text('Operator agent'), findsNothing);
  });

  testWidgets('unknown account scope exposes no selling workspace', (
    tester,
  ) async {
    await _pumpWorkspace(tester, null);

    expect(find.text('Workspace unavailable'), findsOneWidget);
    expect(find.text('Your ticket counter'), findsNothing);
    expect(find.text('Your agent business'), findsNothing);
  });

  test('agent workspace files stay small and scope-specific', () {
    for (final directory in [
      Directory('lib/features/agent/operator'),
      Directory('lib/features/agent/platform'),
      Directory('lib/features/agent/workspace'),
    ]) {
      for (final file in directory.listSync().whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        expect(
          file.readAsLinesSync().length,
          lessThanOrEqualTo(250),
          reason: file.path,
        );
      }
    }
  });
}

Future<void> _pumpWorkspace(WidgetTester tester, AgentScope? scope) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(_SignedInController.new),
        agentIdentityControllerProvider.overrideWith(
          () => _IdentityController(scope),
        ),
        agentAssignmentsControllerProvider.overrideWith(
          _AssignmentsController.new,
        ),
      ],
      child: const MaterialApp(home: AgentHomeScreen()),
    ),
  );
  await tester.pump();
}
