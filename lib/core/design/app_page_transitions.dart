import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — page transition
///
/// A clean Cupertino horizontal slide, pace-tuned. Cupertino stays the base and
/// we change *only* the timeline — nothing is layered on top of the slide:
///   • the interactive edge-swipe-back detector ships **inside** Cupertino's
///     `buildTransitions`, so swipe-to-go-back keeps working on both platforms
///     (and stays in lockstep with the system back button);
///   • `delegatedTransition` recedes the page underneath (parallax + dim), which
///     reads as depth rather than a flat card swap.
///
/// The one deliberate change: stretch the timeline to 600ms (vs Cupertino's
/// stock 500ms) so the slide reads as deliberate instead of a whip. The route
/// honours this because `MaterialRouteTransitionMixin.transitionDuration` reads
/// `transitionDuration` off the active theme builder, so it governs both
/// programmatic push/pop and the swipe-back settle.
///
/// We intentionally do NOT cross-fade the sliding page. Fading an opaque page
/// while it slides makes it translucent mid-flight, so the outgoing screen
/// bleeds through it — a muddy double-exposure. A clean slide stays crisp.
/// The pace is the single knob here: nudge the [Duration] below.
/// ─────────────────────────────────────────────────────────────────────────────
class PartnerPageTransitionsBuilder extends PageTransitionsBuilder {
  const PartnerPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 600);

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
    // The Cupertino slide *and* the interactive back-gesture detector, verbatim.
    // The only thing we changed is the duration (above); the motion itself is
    // stock iOS so it stays crisp and directional.
    return const CupertinoPageTransitionsBuilder().buildTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
