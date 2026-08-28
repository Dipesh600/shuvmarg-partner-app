import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuvmarg_partner_app/core/errors/result.dart';
import 'package:shuvmarg_partner_app/features/agent/assignments/data/agent_assignment.dart';
import 'package:shuvmarg_partner_app/features/agent/assignments/data/agent_assignment_repository.dart';
import 'package:shuvmarg_partner_app/features/agent/assignments/state/agent_assignments_controller.dart';

void main() {
  test(
    'accept refreshes server truth and moves invite into active access',
    () async {
      final gateway = _FakeGateway();
      final container = ProviderContainer(
        overrides: [
          agentAssignmentRepositoryProvider.overrideWithValue(gateway),
        ],
      );
      final subscription = container.listen(
        agentAssignmentsControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(() {
        subscription.close();
        container.dispose();
      });

      await _settle();
      var view = container.read(agentAssignmentsControllerProvider).dataOrNull!;
      expect(view.invitations, hasLength(1));
      expect(gateway.loadCalls, 1);

      await container
          .read(agentAssignmentsControllerProvider.notifier)
          .accept(_id);

      view = container.read(agentAssignmentsControllerProvider).dataOrNull!;
      expect(gateway.acceptCalls, 1);
      expect(gateway.loadCalls, 2);
      expect(view.invitations, isEmpty);
      expect(view.active, hasLength(1));
      expect(view.notice, contains('accepted'));
    },
  );

  test('view keeps terminal invitations out of current access groups', () {
    final view = AgentAssignmentsView(
      items: [
        _assignment(AgentAssignmentStatus.expired),
        _assignment(AgentAssignmentStatus.declined),
        _assignment(AgentAssignmentStatus.revoked),
      ],
    );

    expect(view.invitations, isEmpty);
    expect(view.active, isEmpty);
    expect(view.history, hasLength(2));
    expect(view.pausedOrRemoved, hasLength(1));
  });
}

const _id = '64c000000000000000000001';

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeGateway implements AgentAssignmentGateway {
  var loadCalls = 0;
  var acceptCalls = 0;
  var status = AgentAssignmentStatus.invited;

  @override
  Future<Result<List<AgentAssignment>>> load() async {
    loadCalls += 1;
    return Result.ok([_assignment(status)]);
  }

  @override
  Future<Result<AgentAssignment>> accept(String assignmentId) async {
    acceptCalls += 1;
    status = AgentAssignmentStatus.active;
    return Result.ok(_assignment(status));
  }

  @override
  Future<Result<AgentAssignment>> decline(
    String assignmentId,
    String? reason,
  ) async {
    status = AgentAssignmentStatus.declined;
    return Result.ok(_assignment(status));
  }
}

AgentAssignment _assignment(AgentAssignmentStatus status) {
  return AgentAssignment(
    id: _id,
    status: status,
    brandId: '64c000000000000000000002',
    brandName: 'Dai Bhai Travels',
    accessScope: 'ALL_BUSES',
    permissions: const AssignmentPermissions(
      canSellCash: true,
      canSellOnline: false,
      canCancel: false,
      cancelWindowMins: 0,
      maxSeatsPerBooking: null,
      maxDiscountPct: 0,
    ),
    commission: const AssignmentCommission(mode: 'PERCENT', value: 5),
  );
}
