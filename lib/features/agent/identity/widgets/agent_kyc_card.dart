import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../domain/agent_application_status.dart';
import '../../../../domain/agent_identity.dart';
import '../../../../shared/ui/ui.dart';

/// Where the agent stands in verification.
///
/// Two rules govern this card.
///
/// FIRST: the sentence comes from the server. [AgentIdentity.kycStatusLabel] is
/// written per status *and per scope* — "Verified" means a confirmed phone for an
/// operator agent and a reviewed document set for a platform one — so composing
/// the sentence here would need this widget to re-derive scope rules the backend
/// already owns. The local [AgentApplicationStatus.label] is used only for the
/// pill, where there is no room for a sentence anyway, and a status this build
/// does not recognise falls back to the server's copy and still reads correctly.
///
/// SECOND: cleared verification is not permission to sell. [AgentIdentity
/// .kycCleared] means "this agent's own checks are done" and nothing more. An
/// agent sells only for an operator that has assigned them, and the assignment
/// model does not exist yet — so the cleared state says what actually happens
/// next instead of implying the workspace is about to open.
class AgentKycCard extends StatelessWidget {
  const AgentKycCard({super.key, required this.identity});

  final AgentIdentity identity;

  @override
  Widget build(BuildContext context) {
    final status = identity.kycStatus;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: AppEyebrow('Verification')),
              AppBadge(
                // 'Unknown' — not 'Not started' — when the status is absent or
                // is a member added after this build shipped. Guessing "not
                // started" would tell an agent mid-review that nothing has
                // happened. The sentence below still reads correctly because it
                // comes from the server.
                label: status?.label ?? 'Unknown',
                tone: _toneOf(status),
                icon: _iconOf(status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            identity.kycStatusLabel ??
                'We could not read your verification status. Pull to refresh, '
                    'or contact support if it stays this way.',
            style: AppText.bodyMd,
          ),
          if (identity.kycCleared) ...[
            const SizedBox(height: AppSpacing.sm),
            const _NextStepLine(
              icon: Icons.info_outline_rounded,
              text: 'Verification is done. Selling opens once a bus operator '
                  'adds you to their team with your code — it does not open on '
                  'its own.',
            ),
          ],
          if (identity.createdByOperator) ...[
            const SizedBox(height: AppSpacing.sm),
            const _NextStepLine(
              icon: Icons.badge_outlined,
              text: 'A bus operator registered this account for you.',
            ),
          ],
        ],
      ),
    );
  }

  /// Colour follows what the agent should *do*, not the wire value: green when
  /// nothing is owed, amber when the ball is in their court or a reviewer's, red
  /// when access is closed.
  static AppBadgeTone _toneOf(AgentApplicationStatus? status) =>
      switch (status) {
        AgentApplicationStatus.verifiedBasic ||
        AgentApplicationStatus.approved => AppBadgeTone.success,
        AgentApplicationStatus.phoneVerified => AppBadgeTone.info,
        AgentApplicationStatus.draft ||
        AgentApplicationStatus.pending ||
        AgentApplicationStatus.moreInfo => AppBadgeTone.pending,
        AgentApplicationStatus.rejected ||
        AgentApplicationStatus.suspended => AppBadgeTone.danger,
        // Unrecognised or absent: grey. Never green — an unknown status has not
        // been shown to be good.
        null => AppBadgeTone.neutral,
      };

  static IconData? _iconOf(AgentApplicationStatus? status) => switch (status) {
    AgentApplicationStatus.verifiedBasic ||
    AgentApplicationStatus.approved => Icons.verified_rounded,
    AgentApplicationStatus.rejected ||
    AgentApplicationStatus.suspended => Icons.block_rounded,
    _ => null,
  };
}

/// An icon-led explanatory line. Body copy, not a warning — the tone is "here is
/// what happens next", because none of these states are the agent's fault.
class _NextStepLine extends StatelessWidget {
  const _NextStepLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(text, style: AppText.bodySm)),
      ],
    );
  }
}
