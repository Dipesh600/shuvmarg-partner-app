import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../shared/ui/ui.dart';

class AssignmentEmptyState extends StatelessWidget {
  const AssignmentEmptyState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: AppRadius.cardRadius,
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No operator invitations yet', style: AppText.titleMd),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message ??
                'Share your Agent ID with a bus operator. Their invitation will appear here.',
            style: AppText.bodySm,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AssignmentProblem extends StatelessWidget {
  const AssignmentProblem({
    super.key,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.danger),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message, style: AppText.bodySm)),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton.secondary(label: 'Try again', onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}

class AssignmentSkeleton extends StatelessWidget {
  const AssignmentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppSkeleton(width: 42, height: 42),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: AppSkeleton(height: 18)),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          AppSkeleton(height: 110),
          SizedBox(height: AppSpacing.md),
          AppSkeleton(height: AppSpacing.controlHeight),
        ],
      ),
    );
  }
}
