import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design/design.dart';
import '../../domain/app_role.dart';
import '../../shared/ui/ui.dart';

/// The role picker — the fork between the three personas this app serves.
///
/// The app does not guess who is signing in: the chosen role becomes the
/// `X-App-Source` on the login request, which is what tells the backend which
/// token to issue. So the choice here is load-bearing, not cosmetic, and it
/// happens before any credential is entered.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.xxl,
            AppSpacing.gutter,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppEyebrow('Shuvmarg Partner'),
              const SizedBox(height: AppSpacing.sm),
              Text('How do you work\nwith Shuvmarg?', style: AppText.display2),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Choose your role to sign in. Each role has its own workspace.',
                style: AppText.body,
              ),
              const SizedBox(height: AppSpacing.xxl),
              for (final option in _roleOptions) ...[
                _RoleCard(
                  option: option,
                  onTap: () =>
                      context.go(AppRoutes.signInForRole(option.role)),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: AppButton.ghost(
                  label: 'I use the passenger or bus-owner app',
                  onPressed: () => context.go(AppRoutes.wrongApp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tappable card for one persona: icon, role name, and one line on what the
/// role does inside the app.
class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.option, required this.onTap});

  final _RoleOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: AppRadius.inputRadius,
            ),
            child: Icon(option.icon, size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option.role.label, style: AppText.titleMd),
                const SizedBox(height: 2),
                Text(option.description, style: AppText.bodySm),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

/// Static description of a role card. Ordered as the list is shown.
class _RoleOption {
  const _RoleOption({
    required this.role,
    required this.icon,
    required this.description,
  });

  final AppRole role;
  final IconData icon;
  final String description;
}

const List<_RoleOption> _roleOptions = [
  _RoleOption(
    role: AppRole.agent,
    icon: Icons.confirmation_number_outlined,
    description: 'Book seats for travellers and track your commission.',
  ),
  _RoleOption(
    role: AppRole.conductor,
    icon: Icons.qr_code_scanner_rounded,
    description: 'Check tickets and mark boarding on your trips.',
  ),
  _RoleOption(
    role: AppRole.driver,
    icon: Icons.directions_bus_rounded,
    description: 'Share your live location while you drive.',
  ),
];
