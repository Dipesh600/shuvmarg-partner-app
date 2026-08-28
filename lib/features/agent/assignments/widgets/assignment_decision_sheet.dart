import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../shared/ui/ui.dart';
import '../data/agent_assignment.dart';

enum AssignmentDecision { accept, decline }

class AssignmentDecisionResult {
  const AssignmentDecisionResult(this.decision, [this.reason]);

  final AssignmentDecision decision;
  final String? reason;
}

Future<AssignmentDecisionResult?> showAssignmentDecisionSheet(
  BuildContext context, {
  required AgentAssignment assignment,
  required AssignmentDecision decision,
}) {
  return showModalBottomSheet<AssignmentDecisionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (_) =>
        _AssignmentDecisionSheet(assignment: assignment, decision: decision),
  );
}

class _AssignmentDecisionSheet extends StatefulWidget {
  const _AssignmentDecisionSheet({
    required this.assignment,
    required this.decision,
  });

  final AgentAssignment assignment;
  final AssignmentDecision decision;

  @override
  State<_AssignmentDecisionSheet> createState() =>
      _AssignmentDecisionSheetState();
}

class _AssignmentDecisionSheetState extends State<_AssignmentDecisionSheet> {
  final _reason = TextEditingController();

  bool get _accepting => widget.decision == AssignmentDecision.accept;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl + bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: _accepting
                    ? AppColors.primarySurface
                    : AppColors.dangerSurface,
                borderRadius: AppRadius.buttonRadius,
              ),
              child: Icon(
                _accepting ? Icons.handshake_outlined : Icons.close_rounded,
                color: _accepting ? AppColors.primary : AppColors.danger,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _accepting ? 'Accept this invitation?' : 'Decline invitation?',
              style: AppText.titleLg,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _accepting
                  ? 'You will be able to sell for ${widget.assignment.brandName} once your verification is cleared.'
                  : '${widget.assignment.brandName} will be told that you declined. You can be invited again later.',
              style: AppText.body,
            ),
            if (!_accepting) ...[
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Reason (optional)',
                hint: 'You can briefly explain why',
                controller: _reason,
                maxLines: 3,
                maxLength: 500,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (_accepting)
              AppButton(
                label: 'Accept invitation',
                onPressed: () => Navigator.pop(
                  context,
                  const AssignmentDecisionResult(AssignmentDecision.accept),
                ),
              )
            else
              AppButton.danger(
                label: 'Decline invitation',
                onPressed: () => Navigator.pop(
                  context,
                  AssignmentDecisionResult(
                    AssignmentDecision.decline,
                    _reason.text.trim().isEmpty ? null : _reason.text.trim(),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            AppButton.ghost(
              label: 'Go back',
              fullWidth: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
