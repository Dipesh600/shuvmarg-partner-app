import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../shared/state/view_state.dart';
import '../../../shared/ui/ui.dart';
import 'data/agent_assignment.dart';
import 'state/agent_assignments_controller.dart';
import 'widgets/assignment_card.dart';
import 'widgets/assignment_decision_sheet.dart';
import 'widgets/assignment_states.dart';

class AgentAssignmentsSection extends ConsumerWidget {
  const AgentAssignmentsSection({super.key, required this.kycCleared});

  final bool? kycCleared;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentAssignmentsControllerProvider);
    final controller = ref.read(agentAssignmentsControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          eyebrow: 'Operator access',
          title: 'Your invitations',
          subtitle: 'You decide which operators you want to sell for.',
          trailing: AppButton.ghost(
            label: 'Refresh',
            icon: Icons.refresh_rounded,
            onPressed: state.isBusy ? null : controller.load,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        switch (state) {
          ViewInitial() || ViewLoadingFirst() => const AssignmentSkeleton(),
          ViewData(:final data) ||
          ViewLoadingRefresh(:final data) ||
          ViewSubmitting(:final data?) => _AssignmentContent(
            view: data,
            kycCleared: kycCleared,
            onAccept: (item) =>
                _decide(context, controller, item, AssignmentDecision.accept),
            onDecline: (item) =>
                _decide(context, controller, item, AssignmentDecision.decline),
          ),
          ViewEmpty(:final message) => AssignmentEmptyState(message: message),
          ViewErrorRetryable(:final failure) ||
          ViewSubmitFieldErrors(:final failure) => AssignmentProblem(
            message: failure.message,
            onRetry: controller.load,
          ),
          ViewOffline(:final failure) => AssignmentProblem(
            icon: Icons.wifi_off_rounded,
            message: failure.message,
            onRetry: controller.load,
          ),
          ViewErrorForbidden(:final failure) => AssignmentProblem(
            icon: Icons.lock_outline_rounded,
            message: failure.message,
          ),
          ViewErrorAuth() => const SizedBox.shrink(),
          ViewSubmitting() => const AssignmentSkeleton(),
        },
      ],
    );
  }

  Future<void> _decide(
    BuildContext context,
    AgentAssignmentsController controller,
    AgentAssignment item,
    AssignmentDecision decision,
  ) async {
    final result = await showAssignmentDecisionSheet(
      context,
      assignment: item,
      decision: decision,
    );
    if (result == null || !context.mounted) return;
    if (result.decision == AssignmentDecision.accept) {
      await controller.accept(item.id);
    } else {
      await controller.decline(item.id, result.reason);
    }
  }
}

class _AssignmentContent extends StatelessWidget {
  const _AssignmentContent({
    required this.view,
    required this.kycCleared,
    required this.onAccept,
    required this.onDecline,
  });

  final AgentAssignmentsView view;
  final bool? kycCleared;
  final ValueChanged<AgentAssignment> onAccept;
  final ValueChanged<AgentAssignment> onDecline;

  @override
  Widget build(BuildContext context) {
    if (view.items.isEmpty) return const AssignmentEmptyState();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (view.notice != null) ...[
          _Notice(message: view.notice!, error: view.noticeIsError),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final item in view.invitations) ...[
          AssignmentCard(
            assignment: item,
            kycCleared: kycCleared,
            busy: view.submittingId == item.id,
            actionsLocked: view.submittingId != null,
            onAccept: () => onAccept(item),
            onDecline: () => onDecline(item),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (view.active.isNotEmpty) ...[
          const _GroupLabel('Connected operators'),
          for (final item in view.active) ...[
            AssignmentCard(
              assignment: item,
              kycCleared: kycCleared,
              busy: false,
              actionsLocked: true,
              onAccept: () {},
              onDecline: () {},
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
        if (view.pausedOrRemoved.isNotEmpty) ...[
          const _GroupLabel('Paused or removed'),
          for (final item in view.pausedOrRemoved) ...[
            AssignmentCard(
              assignment: item,
              kycCleared: kycCleared,
              busy: false,
              actionsLocked: true,
              compact: true,
              onAccept: () {},
              onDecline: () {},
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
        if (view.history.isNotEmpty)
          AppCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              title: Text('Previous invitations', style: AppText.titleMd),
              subtitle: Text(
                '${view.history.length} completed',
                style: AppText.caption,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              children: [
                for (final item in view.history) ...[
                  AssignmentCard(
                    assignment: item,
                    kycCleared: kycCleared,
                    busy: false,
                    actionsLocked: true,
                    compact: true,
                    onAccept: () {},
                    onDecline: () {},
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(label, style: AppText.titleMd),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.error});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        Icon(
          error
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          color: error ? AppColors.danger : AppColors.success,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message, style: AppText.bodySm)),
      ],
    ),
  );
}
