import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../shared/state/view_state.dart';
import '../../../shared/ui/ui.dart';
import 'agent_identity_controller.dart';
import 'widgets/agent_code_card.dart';
import 'widgets/agent_kyc_card.dart';
import 'widgets/agent_outlet_card.dart';

/// The identity block on the agent home: code, verification, outlet.
///
/// One exhaustive `switch` over [ViewState] decides the whole shape, so there is
/// no arrangement of flags that can put a skeleton over data or an error beside
/// it. Each failure gets the shape it deserves — retry for a server hiccup, a
/// reconnect prompt when offline, a support line when the account is closed, and
/// no retry at all when the session is gone (the router is already moving the
/// user to sign-in; a button here would race it).
///
/// This section is separate from the account card above it deliberately: that
/// card reads from the session and always renders, so a failure here costs the
/// agent their code, not their whole screen.
class AgentIdentitySection extends ConsumerWidget {
  const AgentIdentitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentIdentityControllerProvider);
    void reload() => ref.read(agentIdentityControllerProvider.notifier).load();

    return switch (state) {
      // Nothing on screen yet. `initial` is unreachable — the controller starts
      // its first load in `build` — but it shares the skeleton either way.
      ViewInitial() || ViewLoadingFirst() => const _IdentitySkeleton(),

      // Loaded, or refetching over data we already have. Same cards; a refresh
      // must never blank the code the agent is in the middle of reading out.
      ViewData(:final data) ||
      ViewLoadingRefresh(:final data) => _IdentityCards(
        view: data,
        isRefreshing: state is ViewLoadingRefresh,
        onRefresh: reload,
      ),

      // This controller only reads, so neither submit state can occur. Handled
      // rather than defaulted so the analyser keeps this switch honest if it
      // ever starts writing.
      ViewSubmitting(:final data) => data == null
          ? const _IdentitySkeleton()
          : _IdentityCards(view: data, isRefreshing: true, onRefresh: reload),
      ViewSubmitFieldErrors(:final failure) => _IdentityProblem(
        message: failure.message,
        onRetry: reload,
      ),

      // An agent always has an identity row once authenticated, so `empty` means
      // the server answered with a shape we did not expect.
      ViewEmpty() => _IdentityProblem(
        message: 'Your agent profile could not be found.',
        onRetry: reload,
      ),

      ViewErrorRetryable(:final failure) => _IdentityProblem(
        message: failure.message,
        onRetry: reload,
      ),

      ViewOffline(:final failure) => _IdentityProblem(
        icon: Icons.wifi_off_rounded,
        message: failure.message,
        onRetry: reload,
      ),

      // Blocked account or a closed gate. Retrying sends the same request to the
      // same refusal, so the only useful action is talking to a human.
      ViewErrorForbidden(:final failure) => _IdentityProblem(
        icon: Icons.lock_outline_rounded,
        message: failure.message,
      ),

      // Session gone. No copy of our own: the redirect is already happening.
      ViewErrorAuth() => const SizedBox.shrink(),
    };
  }
}

/// The loaded cards. The outlet card is omitted rather than emptied when the
/// agent has filled in none of its fields.
class _IdentityCards extends StatelessWidget {
  const _IdentityCards({
    required this.view,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final AgentIdentityView view;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final identity = view.identity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgentCodeCard(identity: identity, sharePayload: view.sharePayload),
        const SizedBox(height: AppSpacing.md),
        AgentKycCard(identity: identity),
        if (identity.hasOutletDetails) ...[
          const SizedBox(height: AppSpacing.md),
          AgentOutletCard(identity: identity),
        ],
        const SizedBox(height: AppSpacing.xs),
        // Verification advances on the server, so the agent needs a way to ask
        // again without leaving the screen.
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton.ghost(
            label: 'Refresh status',
            icon: Icons.refresh_rounded,
            isLoading: isRefreshing,
            onPressed: onRefresh,
          ),
        ),
      ],
    );
  }
}

/// A failure, with retry only where retrying could work.
class _IdentityProblem extends StatelessWidget {
  const _IdentityProblem({
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
  });

  final String message;
  final IconData icon;

  /// `null` for failures a retry cannot fix — the button is then omitted rather
  /// than shown and disabled, which would look like a bug.
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
              Icon(icon, size: 20, color: AppColors.danger),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Agent code unavailable', style: AppText.titleMd),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(message, style: AppText.bodySm),
                  ],
                ),
              ),
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

/// Placeholder shaped like the code card it replaces, so the layout does not
/// jump when the real content lands.
class _IdentitySkeleton extends StatelessWidget {
  const _IdentitySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(width: 96, height: 10),
              SizedBox(height: AppSpacing.sm),
              AppSkeleton(height: 52),
              SizedBox(height: AppSpacing.sm),
              AppSkeleton(height: 12),
              SizedBox(height: AppSpacing.xxs),
              AppSkeleton(width: 180, height: 12),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(width: 80, height: 10),
              SizedBox(height: AppSpacing.sm),
              AppSkeleton(height: 12),
              SizedBox(height: AppSpacing.xxs),
              AppSkeleton(width: 140, height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
