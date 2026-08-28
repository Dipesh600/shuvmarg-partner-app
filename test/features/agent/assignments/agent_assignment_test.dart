import 'package:flutter_test/flutter_test.dart';
import 'package:shuvmarg_partner_app/features/agent/assignments/data/agent_assignment.dart';

void main() {
  group('AgentAssignment backend contract', () {
    test('parses every backend lifecycle status without inventing one', () {
      for (final status in AgentAssignmentStatus.values) {
        final assignment = AgentAssignment.fromJson(_json(status: status.wire));
        expect(assignment.status, status);
      }
      expect(
        () => AgentAssignment.fromJson(_json(status: 'APPROVED')),
        throwsFormatException,
      );
    });

    test('unknown or absent permissions fail closed', () {
      final assignment = AgentAssignment.fromJson(
        _json(permissions: const {'newPermission': true}),
      );
      expect(assignment.permissions.canSellCash, isFalse);
      expect(assignment.permissions.canSellOnline, isFalse);
      expect(assignment.permissions.canCancel, isFalse);
    });

    test('formats access and each commission mode for an agent', () {
      expect(
        AgentAssignment.fromJson(_json(accessScope: 'ROUTES')).accessLabel,
        'Selected routes',
      );
      expect(
        AgentAssignment.fromJson(
          _json(commission: const {'mode': 'PERCENT', 'value': 7.5}),
        ).commission.label,
        '7.5% of each booking',
      );
      expect(
        AgentAssignment.fromJson(
          _json(commission: const {'mode': 'FLAT_PER_SEAT', 'value': 50}),
        ).commission.label,
        'Rs 50 per seat',
      );
      expect(
        AgentAssignment.fromJson(
          _json(commission: const {'mode': 'FLAT_PER_BOOKING', 'value': 100}),
        ).commission.label,
        'Rs 100 per booking',
      );
    });

    test('keeps backend dates as local DateTime values', () {
      final assignment = AgentAssignment.fromJson(_json());
      expect(assignment.invitedAt, isNotNull);
      expect(assignment.expiresAt, isNotNull);
      expect(
        assignment.expiresAt!.difference(assignment.invitedAt!),
        const Duration(days: 7),
      );
    });
  });
}

Map<String, dynamic> _json({
  String status = 'INVITED',
  String accessScope = 'ALL_BUSES',
  Map<String, dynamic> permissions = const {
    'canSellCash': true,
    'canSellOnline': false,
    'canCancel': false,
    'cancelWindowMins': 0,
    'maxSeatsPerBooking': 4,
    'maxDiscountPct': 0,
  },
  Map<String, dynamic> commission = const {'mode': 'PERCENT', 'value': 5},
}) {
  return {
    'assignmentId': '64c000000000000000000001',
    'status': status,
    'brand': {'id': '64c000000000000000000002', 'name': 'Dai Bhai Travels'},
    'invitedAt': '2026-08-28T10:00:00.000Z',
    'expiresAt': '2026-09-04T10:00:00.000Z',
    'accessScope': accessScope,
    'permissions': permissions,
    'commission': commission,
  };
}
