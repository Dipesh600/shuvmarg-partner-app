import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design/design.dart';
import '../../shared/session/session_providers.dart';
import '../../shared/session/session_state.dart';

/// The official Shuvmarg Partner Splash Screen.
///
/// Features:
/// - Full-bleed scenic mountain road backdrop (`splash_screen.webp`).
/// - Prominent, 2x enlarged orange gradient app icon squircle with crisp white brand mark.
/// - Authentic "ShuvMarg" wordmark rendered with the bundled 'Neue Machina' brand font.
/// - "PARTNER" badge pill aligned with the wordmark.
/// - Subtitle and three trust features (Nepal First, Safe & Reliable, Always Connected).
/// - Transparent, human-friendly loader and frosted bottom brand pill.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _progressAnimation;

  Timer? _navigationTimer;

  static const Duration _splashDuration = Duration(milliseconds: 2200);

  /// Content images shown across the shared entry flow (this splash, welcome,
  /// sign-in and the support sheet). Kept in step with the `Image.asset` paths
  /// in those screens. Warmed once below so none of them pop in later.
  static const List<String> _entryFlowImageAssets = [
    'assets/images/splash_screen.webp',
    'assets/images/login_screen_background_button.webp',
    'assets/images/logo_orange.webp',
    'assets/images/agent_ticket_icon.webp',
    'assets/images/conductor_icon.webp',
    'assets/images/Driver_stering_icon.webp',
    'assets/images/support_icon.png',
  ];

  bool _didPrecacheEntryAssets = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: AppMotion.expoOut),
      ),
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.95, curve: Curves.easeInOutCubic),
    );

    _controller.forward();

    _navigationTimer = Timer(_splashDuration, _navigateToNext);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm the raster cache for the whole entry flow while the splash holds its
    // ~2.2s dwell. Without this, `Image.asset` on welcome/sign-in decodes lazily
    // on first paint — blank, then a pop-in mid-transition. Precaching here means
    // those screens render their artwork on the very first frame. Uses a plain
    // `AssetImage` (no `cacheWidth`) so the cache key matches the widgets exactly.
    if (_didPrecacheEntryAssets) return;
    _didPrecacheEntryAssets = true;
    for (final asset in _entryFlowImageAssets) {
      precacheImage(
        AssetImage(asset),
        context,
        onError: (error, _) =>
            debugPrint('Splash: skipped precache of $asset ($error)'),
      );
    }
  }

  void _navigateToNext() {
    if (!mounted) return;

    final session = ref.read(sessionControllerProvider);
    if (session is SessionSignedIn) {
      context.go(AppRoutes.homeForRole(session.session.activeRole));
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-screen Scenic Mountain Road Artwork
          Image.asset(
            'assets/images/splash_screen.webp',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),

          // 2. Foreground Brand & Features Content
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.11),

                  // App Icon Squircle (adjusted to 92x92 with 26px radius)
                  Container(
                    height: 92,
                    width: 92,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.orange400,
                          AppColors.primary,
                          AppColors.orange600,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.42),
                          blurRadius: 28,
                          offset: const Offset(0, 11),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Transform.scale(
                        scale: 2.3,
                        child: Image.asset(
                          'assets/images/logo_orange.webp',
                          fit: BoxFit.contain,
                          color: AppColors.white,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ShuvMarg Wordmark (using Neue Machina font) + PARTNER Badge Lockup
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Shuv',
                              style: TextStyle(
                                fontFamily: 'Neue Machina',
                                fontSize: 36,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            TextSpan(
                              text: 'Marg',
                              style: TextStyle(
                                fontFamily: 'Neue Machina',
                                fontSize: 36,
                                fontWeight: FontWeight.w400,
                                color: AppColors.primary,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'PARTNER',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Subheadline
                  const Text(
                    'Mobility Operations Platform',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Subtle divider line with center dot
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 1,
                        color: AppColors.neutral200,
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 4.5,
                        height: 4.5,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 42,
                        height: 1,
                        color: AppColors.neutral200,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Three Trust Badges in a Row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _TrustFeature(
                          icon: Icons.shield_outlined,
                          title: 'Nepal First',
                        ),
                        _FeatureDivider(),
                        const _TrustFeature(
                          icon: Icons.directions_bus_outlined,
                          title: 'Safe & Reliable',
                        ),
                        _FeatureDivider(),
                        const _TrustFeature(
                          icon: Icons.hub_outlined,
                          title: 'Always Connected',
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Transparent Loading Bar Area
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Friendly, clear loading text
                        Text(
                          'Getting things ready...',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white.withValues(alpha: 0.95),
                            shadows: [
                              Shadow(
                                color: AppColors.neutral900.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Sleek transparent progress capsule
                        SizedBox(
                          width: 220,
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, _) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  height: 3.5,
                                  color: AppColors.white.withValues(alpha: 0.3),
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: _progressAnimation.value,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.orange400,
                                            AppColors.primary,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Bottom Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutral900.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Nepal',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        _Dot(),
                        Text(
                          'Safe',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        _Dot(),
                        Text(
                          'Reliable',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        _Dot(),
                        Text(
                          'Connected',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small orange dot divider for the footer pill.
class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 3.5,
      height: 3.5,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Single trust badge element (Icon + Label).
class _TrustFeature extends StatelessWidget {
  const _TrustFeature({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: AppColors.primary,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Vertical hairline divider between feature badges.
class _FeatureDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.neutral200,
    );
  }
}
