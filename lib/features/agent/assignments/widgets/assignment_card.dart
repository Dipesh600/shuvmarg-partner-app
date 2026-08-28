import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design.dart';
import '../../../../shared/ui/ui.dart';
import '../data/agent_assignment.dart';
import 'assignment_terms.dart';

class AssignmentCard extends StatelessWidget {
  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.kycCleared,
    required this.busy,
    required this.actionsLocked,
    required this.onAccept,
    required this.onDecline,
    this.compact = false,
  });

  final AgentAssignment assignment;
  final bool? kycCleared;
  final bool busy;
  final bool actionsLocked;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BrandMark(name: assignment.brandName),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(assignment.brandName, style: AppText.titleMd),
                    const SizedBox(height: 2),
                    Text(_headline, style: AppText.bodySm),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppBadge(label: _statusLabel, tone: _tone),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: AppSpacing.md),
            AssignmentTerms(assignment: assignment),
          ],
          if (assignment.status == AgentAssignmentStatus.invited) ...[
            const SizedBox(height: AppSpacing.sm),
            _TimingLine(expiresAt: assignment.expiresAt),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'Decline',
                    onPressed: busy || actionsLocked ? null : onDecline,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Accept',
                    isLoading: busy,
                    onPressed: busy || actionsLocked ? null : onAccept,
                  ),
                ),
              ],
            ),
          ],
          if (assignment.status == AgentAssignmentStatus.active &&
              kycCleared == false) ...[
            const SizedBox(height: AppSpacing.md),
            const _InfoBanner(
              icon: Icons.verified_user_outlined,
              message:
                  'Access accepted. Complete verification before selling tickets.',
            ),
          ],
          if (assignment.status == AgentAssignmentStatus.active &&
              kycCleared == true &&
              assignment.permissions.canSellCash) ...[
            const SizedBox(height: AppSpacing.md),
            const _InfoBanner(
              icon: Icons.check_circle_outline_rounded,
              message: 'You are cleared to sell tickets for this operator.',
              success: true,
            ),
          ],
          if (assignment.status == AgentAssignmentStatus.active &&
              kycCleared == true &&
              !assignment.permissions.canSellCash) ...[
            const SizedBox(height: AppSpacing.md),
            const _InfoBanner(
              icon: Icons.info_outline_rounded,
              message:
                  'This operator has not enabled cash ticket sales for you.',
            ),
          ],
          if (assignment.status == AgentAssignmentStatus.active &&
              kycCleared == null) ...[
            const SizedBox(height: AppSpacing.md),
            const _InfoBanner(
              icon: Icons.hourglass_top_rounded,
              message:
                  'Checking whether your verification is ready for selling.',
            ),
          ],
          if (assignment.status == AgentAssignmentStatus.suspended) ...[
            const SizedBox(height: AppSpacing.md),
            const _InfoBanner(
              icon: Icons.pause_circle_outline_rounded,
              message:
                  'This operator paused your selling access. Contact them for details.',
            ),
          ],
          if (assignment.status == AgentAssignmentStatus.revoked) ...[
            const SizedBox(height: AppSpacing.md),
            const _InfoBanner(
              icon: Icons.block_outlined,
              message: 'This operator removed your selling access.',
            ),
          ],
        ],
      ),
    );
  }

  String get _statusLabel {
    if (assignment.status == AgentAssignmentStatus.active) {
      if (kycCleared == true && assignment.permissions.canSellCash) {
        return 'Ready to sell';
      }
      if (kycCleared == true) return 'Access limited';
      if (kycCleared == false) return 'Verify first';
      return 'Accepted';
    }
    return assignment.status.label;
  }

  String get _headline => switch (assignment.status) {
    AgentAssignmentStatus.invited => 'Invited you to sell tickets',
    AgentAssignmentStatus.active => 'Your operator connection is active',
    AgentAssignmentStatus.suspended => 'Your access is temporarily paused',
    AgentAssignmentStatus.revoked => 'This connection has ended',
    AgentAssignmentStatus.declined => 'Invitation declined',
    AgentAssignmentStatus.expired => 'Invitation was not answered in time',
  };

  AppBadgeTone get _tone => switch (assignment.status) {
    AgentAssignmentStatus.active =>
      kycCleared == true && assignment.permissions.canSellCash
          ? AppBadgeTone.success
          : AppBadgeTone.pending,
    AgentAssignmentStatus.invited => AppBadgeTone.pending,
    AgentAssignmentStatus.suspended => AppBadgeTone.special,
    AgentAssignmentStatus.revoked ||
    AgentAssignmentStatus.declined => AppBadgeTone.danger,
    AgentAssignmentStatus.expired => AppBadgeTone.neutral,
  };
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: AppRadius.buttonRadius,
      ),
      child: Text(
        name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
        style: AppText.titleMd.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _TimingLine extends StatelessWidget {
  const _TimingLine({required this.expiresAt});

  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    final value = expiresAt == null
        ? 'No expiry was provided'
        : 'Accept before ${DateFormat('d MMM, h:mm a').format(expiresAt!)}';
    return Row(
      children: [
        const Icon(Icons.schedule_rounded, size: 17, color: AppColors.warning),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(value, style: AppText.caption)),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.message,
    this.success = false,
  });

  final IconData icon;
  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.success : AppColors.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(message, style: AppText.bodySm.copyWith(color: color)),
        ),
      ],
    );
  }
}
