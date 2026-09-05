import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/session.dart';
import '../../shared/ui/ui.dart';
import 'brand_header.dart';

/// Landing scaffold shared by the three persona home screens.
///
/// Each persona's home is its own widget in its own folder — the workspace-
/// isolation rule — but they share this chrome: the brand-header bleed, the
/// gold-accented greeting, and a sign-out action. Persona-specific content is
/// passed in as [body]; nothing role-dependent lives here.
class PersonaHomeScaffold extends StatelessWidget {
  const PersonaHomeScaffold({
    super.key,
    required this.user,
    this.greetingName,
    required this.onSignOut,
    required this.body,
  });

  final AuthenticatedUser user;

  /// Persona-specific display name. Driver profiles own their own name and may
  /// intentionally differ from the shared login account used by other roles.
  final String? greetingName;

  /// Invoked by the header's sign-out action. The screen wires this to the
  /// session controller; the scaffold stays presentational.
  final VoidCallback onSignOut;

  /// Persona-specific cards rendered in the white sheet, top-aligned.
  final List<Widget> body;

  @override
  Widget build(BuildContext context) {
    return BrandHeaderScaffold(
      header: BrandGreeting(
        salutation: 'Welcome back,',
        name: _shortName(greetingName ?? user.name),
        trailing: BrandHeaderAction(
          icon: Icons.logout_rounded,
          onTap: onSignOut,
          tooltip: 'Sign out',
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.xl,
          AppSpacing.gutter,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: body,
        ),
      ),
    );
  }
}

String _shortName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'there';
  final space = trimmed.indexOf(' ');
  return space == -1 ? trimmed : trimmed.substring(0, space);
}

/// Full-screen brand loader shown while a screen waits for the session — a
/// defensive fallback; the router guard normally keeps an unauthenticated user
/// out of a persona subtree in the first place.
class WorkspaceLoader extends StatelessWidget {
  const WorkspaceLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.canvas,
      child: Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }
}

/// Signed-in account summary, built entirely from the real session — no
/// placeholder data. Shows the name, role, contact details the login returned,
/// and whether the account is verified.
class WorkspaceAccountCard extends StatelessWidget {
  const WorkspaceAccountCard({
    super.key,
    required this.user,
    required this.roleLabel,
  });

  final AuthenticatedUser user;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final email = user.email;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: user.name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppText.titleMd,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(roleLabel, style: AppText.bodySm),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppBadge(
                label: user.isVerified ? 'Verified' : 'Unverified',
                tone: user.isVerified
                    ? AppBadgeTone.success
                    : AppBadgeTone.pending,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(icon: Icons.phone_outlined, value: user.phone),
          if (email != null && email.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(icon: Icons.mail_outline_rounded, value: email),
          ],
        ],
      ),
    );
  }
}

/// A calm, honest note about capabilities that are not built yet — the
/// graceful-degradation alternative to a broken button or an empty screen.
class WorkspaceNoteCard extends StatelessWidget {
  const WorkspaceNoteCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.construction_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: AppText.bodySm)),
        ],
      ),
    );
  }
}

/// Round monogram from the first letter of the account name.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    return Container(
      height: 44,
      width: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primarySurface,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppText.titleMd.copyWith(color: AppColors.primary),
      ),
    );
  }
}

/// Icon + value line used inside [WorkspaceAccountCard].
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: AppText.bodySm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
