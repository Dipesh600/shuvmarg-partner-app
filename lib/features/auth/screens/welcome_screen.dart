import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shuvmarg_partner_app/core/theme/app_theme.dart';
import 'package:shuvmarg_partner_app/core/routes/app_routes.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              children: [
                // ── Hero illustration ──────────────────────────────────
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.80),
                          AppColors.primaryDark.withOpacity(0.95),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.stroke),
                      boxShadow: AppShadows.card,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Decorative circles
                        Positioned(
                          top: -40,
                          right: -40,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accentLime.withOpacity(0.06),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          left: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.secondary.withOpacity(0.12),
                            ),
                          ),
                        ),

                        // Illustration content
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Bus icon composition
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: AppColors.accentLime.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accentLime.withOpacity(0.30),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.directions_bus_rounded,
                                size: 52,
                                color: AppColors.accentLime,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            // Earnings illustration
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _EarningChip(label: 'NPR 850', icon: Icons.confirmation_number_outlined),
                                const SizedBox(width: AppSpacing.md),
                                _EarningChip(label: '+8%', icon: Icons.trending_up_rounded, isAccent: true),
                                const SizedBox(width: AppSpacing.md),
                                _EarningChip(label: '✓ Done', icon: Icons.check_circle_outline),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Copy + CTAs ────────────────────────────────────────
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Earn by selling\nbus tickets',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Join the Shuvmarg network and earn commission on every ticket you book.',
                          style: AppTextStyles.bodyMed(AppColors.textSecond),
                          maxLines: 2,
                        ),
                        const Spacer(),

                        // Primary CTA — Apply (signup flow)
                        _ApplyCTA(onTap: () => context.push(AppRoutes.phoneEntry)),
                        const SizedBox(height: AppSpacing.lg),

                        // Secondary — Login (dedicated login screen)
                        Center(
                          child: GestureDetector(
                            onTap: () => context.push(AppRoutes.login),
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.bodyMed(AppColors.textSecond),
                                children: [
                                  const TextSpan(text: 'Already an agent?  '),
                                  TextSpan(
                                    text: 'Log in',
                                    style: AppTextStyles.labelMed(AppColors.accentLime),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EarningChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isAccent;
  const _EarningChip({required this.label, required this.icon, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAccent
            ? AppColors.accentLime.withOpacity(0.15)
            : Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(
          color: isAccent
              ? AppColors.accentLime.withOpacity(0.35)
              : AppColors.stroke,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: isAccent ? AppColors.accentLime : AppColors.textSecond),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isAccent ? AppColors.accentLime : AppColors.textSecond,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyCTA extends StatefulWidget {
  final VoidCallback onTap;
  const _ApplyCTA({required this.onTap});

  @override
  State<_ApplyCTA> createState() => _ApplyCTAState();
}

class _ApplyCTAState extends State<_ApplyCTA> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.accentLime,
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: AppShadows.glow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Apply to become an agent',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryDark, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
