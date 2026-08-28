import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../shared/ui/ui.dart';
import '../data/agent_assignment.dart';

class AssignmentTerms extends StatelessWidget {
  const AssignmentTerms({super.key, required this.assignment});

  final AgentAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final permissions = assignment.permissions;
    return AppInsetPanel(
      child: Column(
        children: [
          _TermRow(
            icon: Icons.directions_bus_outlined,
            label: 'Tickets you can sell',
            value: assignment.accessLabel,
          ),
          const AppDivider(),
          _TermRow(
            icon: Icons.payments_outlined,
            label: 'Payment methods',
            value: _paymentMethods(permissions),
          ),
          const AppDivider(),
          _TermRow(
            icon: Icons.event_seat_outlined,
            label: 'Seats per booking',
            value: permissions.maxSeatsPerBooking == null
                ? 'No limit set'
                : 'Up to ${permissions.maxSeatsPerBooking}',
          ),
          const AppDivider(),
          _TermRow(
            icon: Icons.percent_rounded,
            label: 'Your commission',
            value: assignment.commission.label,
          ),
          if (permissions.canCancel || permissions.maxDiscountPct > 0) ...[
            const AppDivider(),
            _TermRow(
              icon: Icons.tune_rounded,
              label: 'Extra permissions',
              value: _extraPermissions(permissions),
            ),
          ],
        ],
      ),
    );
  }

  String _paymentMethods(AssignmentPermissions permissions) {
    if (permissions.canSellCash && permissions.canSellOnline) {
      return 'Cash now · Online coming later';
    }
    if (permissions.canSellCash) return 'Cash';
    if (permissions.canSellOnline) return 'Online coming later';
    return 'No sales permitted';
  }

  String _extraPermissions(AssignmentPermissions permissions) {
    final values = <String>[
      if (permissions.canCancel)
        permissions.cancelWindowMins > 0
            ? 'Cancel within ${permissions.cancelWindowMins} minutes'
            : 'Cancellation allowed',
      if (permissions.maxDiscountPct > 0)
        'Discount up to ${permissions.maxDiscountPct}%',
    ];
    return values.join(' · ');
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.caption),
              const SizedBox(height: 2),
              Text(value, style: AppText.bodyMd),
            ],
          ),
        ),
      ],
    );
  }
}
