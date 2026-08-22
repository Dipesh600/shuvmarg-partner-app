import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — page transition
///
/// A refined take on the Cupertino horizontal slide. We keep Cupertino as the
/// *base* because no single Material builder gives us both of these at once:
///   • the interactive edge-swipe-back detector ships **inside** its
///     `buildTransitions`, so swipe-to-go-back keeps working on both platforms
///     (and stays in lockstep with the system back button);
///   • its `delegatedTransition` recedes the page underneath (parallax + dim),
///     which reads as depth rather than a flat card swap.
///
/// On top of that base we make two changes to trade the stock "hard, fast
/// slide" for a calmer, more premium feel:
///   1. Stretch the timeline a little — 550ms vs Cupertino's stock 500ms — so
///      the motion reads as deliberate instead of a whip. The route picks this
///      up from the theme (`MaterialRouteTransitionMixin` reads
///      `transitionDuration` off the active builder), so it governs both
///      programmatic push/pop and the swipe-back settle.
///   2. Cross-fade the page with a decelerating curve so a screen *melts* into
///      place over the receding one instead of racing in as a hard rectangle.
///      `easeOutCubic` front-loads the reveal, so the incoming page is
///      essentially opaque by ~70% of the slide — no lingering translucent
///      ghost at the end. This soft dissolve is what removes the "speedy /
///      jittery" read the stock slide had.
/// ─────────────────────────────────────────────────────────────────────────────
class LiquidPageTransitionsBuilder extends PageTransitionsBuilder {
  const LiquidPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 550);

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      const CupertinoPageTransitionsBuilder().delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // The Cupertino slide *and* the interactive back-gesture detector.
    final Widget slide = const CupertinoPageTransitionsBuilder()
        .buildTransitions<T>(route, context, animation, secondaryAnimation, child);

    // Melt the page in (and out, on pop) over the receding page beneath it.
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      child: slide,
    );
  }
}
