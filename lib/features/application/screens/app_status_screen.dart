import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';
import 'package:shuvmarg_partner_app/features/application/providers/application_provider.dart';
import 'package:shuvmarg_partner_app/shared/widgets/app_widgets.dart';

class AppStatusScreen extends ConsumerStatefulWidget {
  const AppStatusScreen({super.key});

  @override
  ConsumerState<AppStatusScreen> createState() => _AppStatusScreenState();
}

class _AppStatusScreenState extends ConsumerState<AppStatusScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Load real status from server on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await ref.read(applicationProvider.notifier).loadStatus();
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(applicationProvider);
    final status = draft.applicationStatus ?? 'PENDING';
    final agentId = draft.serverAgentId ?? '—';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.accentLime,
          backgroundColor: AppColors.bgSurface,
          child: _buildBody(status, agentId, draft),
        ),
      ),
    );
  }

  Widget _buildBody(String status, String agentId, ApplicationDraft draft) {
    switch (status) {
      case 'APPROVED':
        return _ApprovedView(onContinue: () => context.go(AppRoutes.agentHome));
      case 'REJECTED':
        return ListView(children: [
          _RejectedView(
            reason: draft.rejectionReason ?? '',
            onReapply: () => context.go(AppRoutes.appStep1Personal),
          ),
        ]);
      case 'MORE_INFO':
        return ListView(children: [
          _MoreInfoView(
            message: draft.moreInfoRequest ?? '',
            agentId: agentId,
          ),
        ]);
      default: // PENDING or null
        return ListView(children: [
          _PendingView(
            agentId: agentId,
            isRefreshing: _isRefreshing,
          ),
        ]);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PENDING STATE
// ─────────────────────────────────────────────────────────────────────────────

class _PendingView extends StatelessWidget {
  final String agentId;
  final bool isRefreshing;
  const _PendingView({required this.agentId, required this.isRefreshing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),

          // Illustration
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.30), width: 1.5),
            ),
            child: const Icon(Icons.hourglass_top_rounded, size: 48, color: AppColors.secondary),
          ),

          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Application under review',
            style: AppTextStyles.heading2(AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            "We'll review your details and get back to you within 1–2 business days via SMS and notification.",
            style: AppTextStyles.bodyMed(AppColors.textSecond),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // Application ID card
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.xxl),
            child: Column(
              children: [
                Text('Application ID', style: AppTextStyles.labelSm(AppColors.textSecond)),
                const SizedBox(height: AppSpacing.sm),
                Text(agentId, style: AppTextStyles.heroNumSm(AppColors.accentLime)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Share this ID if you contact support',
                  style: AppTextStyles.bodySmall(AppColors.textSecond),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Refresh hint
          if (isRefreshing)
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentLime),
            )
          else
            Text(
              'Pull down to refresh status',
              style: AppTextStyles.bodySmall(AppColors.textSecond.withOpacity(0.6)),
            ),

          const SizedBox(height: AppSpacing.xxxl),

          OutlineButton(
            label: 'WhatsApp Support →',
            onPressed: () async {
              final uri = Uri.parse('https://wa.me/9779800000000?text=Agent+ID+$agentId');
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
            borderColor: const Color(0xFF25D366),
            textColor: const Color(0xFF25D366),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MORE INFO STATE
// ─────────────────────────────────────────────────────────────────────────────

class _MoreInfoView extends StatelessWidget {
  final String message;
  final String agentId;
  const _MoreInfoView({required this.message, required this.agentId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Amber header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl,
          ),
          color: AppColors.warning.withOpacity(0.12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.priority_high_rounded, color: AppColors.warning, size: 24),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Action Required', style: AppTextStyles.labelLg(AppColors.warning)),
                    Text('Additional information needed', style: AppTextStyles.bodySmall(AppColors.textSecond)),
                  ],
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Our team has reviewed your application and needs:',
                style: AppTextStyles.bodyMed(AppColors.textSecond),
              ),
              const SizedBox(height: AppSpacing.lg),

              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded, color: AppColors.accentLime, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        message.isNotEmpty ? message : 'Please provide the additional information as requested.',
                        style: AppTextStyles.bodyMed(AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              PrimaryButton(
                label: 'Update Documents →',
                onPressed: () => context.push(AppRoutes.appStep3Documents),
              ),
              const SizedBox(height: AppSpacing.lg),

              Center(
                child: Text(
                  'Please respond within 7 days',
                  style: AppTextStyles.bodySmall(AppColors.textSecond),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REJECTED STATE
// ─────────────────────────────────────────────────────────────────────────────

class _RejectedView extends StatelessWidget {
  final String reason;
  final VoidCallback onReapply;
  const _RejectedView({required this.reason, required this.onReapply});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Red header bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl,
          ),
          color: AppColors.error.withOpacity(0.10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: AppColors.error, size: 24),
              ),
              const SizedBox(width: AppSpacing.lg),
              Text('Application Not Approved', style: AppTextStyles.labelLg(AppColors.error)),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Text('Reason:', style: AppTextStyles.labelMed(AppColors.textSecond)),
              const SizedBox(height: AppSpacing.lg),

              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  reason.isNotEmpty
                      ? reason
                      : 'Your application did not meet our requirements at this time.',
                  style: AppTextStyles.bodyMed(AppColors.textPrimary),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              Text(
                'You may reapply after correcting the flagged documents.',
                style: AppTextStyles.bodyMed(AppColors.textSecond),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              PrimaryButton(label: 'Reapply →', onPressed: onReapply),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APPROVED STATE
// ─────────────────────────────────────────────────────────────────────────────

class _ApprovedView extends StatelessWidget {
  final VoidCallback onContinue;
  const _ApprovedView({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppColors.accentLime.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentLime.withOpacity(0.40), width: 1.5),
              boxShadow: AppShadows.glow,
            ),
            child: const Icon(Icons.check_rounded, size: 52, color: AppColors.accentLime),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            "You're approved!",
            style: AppTextStyles.heading1(AppColors.accentLime),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Welcome to the Shuvmarg network. Start booking tickets and earning commission.',
            style: AppTextStyles.bodyMed(AppColors.textSecond),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          PrimaryButton(label: 'Go to Dashboard →', onPressed: onContinue),
        ],
      ),
    );
  }
}
