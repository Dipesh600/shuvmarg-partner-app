import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design/design.dart';
import '../../domain/app_role.dart';

/// The role picker / landing screen of Shuvmarg Partner.
///
/// Features:
/// - Top brand header lockup with logo squircle, "ShuvMarg", and "PARTNER" badge.
/// - Hero headline "How do you work with Shuvmarg?" with orange accent bar.
/// - 3D illustrated role cards:
///     • Full-width Agent card with 3D ticket asset
///     • Side-by-side Conductor & Driver cards with 3D scanner and steering wheel assets
/// - Secondary link to the passenger/bus-owner app.
/// - Scenic mountain road bottom backdrop (`background_icon.webp`).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Seamless Mountain Highway Bus Backdrop (login_screen_background_button.webp)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/login_screen_background_button.webp',
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. Foreground Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Brand Header Lockup
                  const _WelcomeBrandHeader(),
                  const SizedBox(height: 52),

                  // Hero Title (Centered with ShuvMarg logo font combination)
                  const Center(
                    child: Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(
                        style: TextStyle(
                          fontFamily: 'Neue Machina',
                          fontSize: 34,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                          height: 1.18,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(text: 'How do you work\nwith '),
                          TextSpan(
                            text: 'Shuv',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: 'Marg',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(text: '?'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Orange Accent Bar (Centered)
                  Center(
                    child: Container(
                      height: 4,
                      width: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Subtitle
                  const Center(
                    child: Text(
                      'Choose your role to sign in.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Role Card 1: Agent (Full Width)
                  _AgentRoleCard(
                    onTap: () => context.push(
                      AppRoutes.signInForRole(AppRole.agent),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Role Cards 2 & 3: Conductor & Driver (Side by Side Grid)
                  Row(
                    children: [
                      Expanded(
                        child: _CompactRoleCard(
                          title: 'Conductor',
                          description: 'Check tickets\nand mark boarding.',
                          assetPath: 'assets/images/conductor_icon.webp',
                          onTap: () => context.push(
                            AppRoutes.signInForRole(AppRole.conductor),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _CompactRoleCard(
                          title: 'Driver',
                          description: 'Share your live\nlocation while you drive.',
                          assetPath: 'assets/images/Driver_stering_icon.webp',
                          onTap: () => context.push(
                            AppRoutes.signInForRole(AppRole.driver),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Secondary Link: Passenger or Bus Owner
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Passenger or bus owner?',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.wrongApp),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Open the main app',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom padding ensuring clean breathing room over the scenery
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Top Brand Lockup: Squircle + "ShuvMarg" (Neue Machina) + "PARTNER" badge.
class _WelcomeBrandHeader extends StatelessWidget {
  const _WelcomeBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Squircle Icon
        Container(
          height: 32,
          width: 32,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.orange400,
                AppColors.primary,
              ],
            ),
          ),
          child: Center(
            child: Transform.scale(
              scale: 2.1,
              child: Image.asset(
                'assets/images/logo_orange.webp',
                fit: BoxFit.contain,
                color: AppColors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // PARTNER Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Text(
            'PARTNER',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// Large, prominent Agent Role Card with 3D Ticket Asset.
class _AgentRoleCard extends StatefulWidget {
  const _AgentRoleCard({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_AgentRoleCard> createState() => _AgentRoleCardState();
}

class _AgentRoleCardState extends State<_AgentRoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 18, 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.white,
                AppColors.canvasAuth,
                AppColors.orange50,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.border,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.neutral900.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 3D Ticket Icon Asset
              SizedBox(
                height: 72,
                width: 78,
                child: Image.asset(
                  'assets/images/agent_ticket_icon.webp',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Agent',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Book seats for travellers and track your commission.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),

              // Orange Chevron
              Container(
                height: 32,
                width: 32,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 26,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact Side-by-Side Role Card (Conductor / Driver).
class _CompactRoleCard extends StatefulWidget {
  const _CompactRoleCard({
    required this.title,
    required this.description,
    required this.assetPath,
    required this.onTap,
  });

  final String title;
  final String description;
  final String assetPath;
  final VoidCallback onTap;

  @override
  State<_CompactRoleCard> createState() => _CompactRoleCardState();
}

class _CompactRoleCardState extends State<_CompactRoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neutral900.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 3D Device / Steering Icon Asset
              SizedBox(
                height: 52,
                width: 48,
                child: Image.asset(
                  widget.assetPath,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 8),

              // Title, Chevron, and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
