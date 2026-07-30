import 'package:flutter/animation.dart';

/// Spacing, radius, and other dimension tokens, per docs/DESIGN_SYSTEM.md
/// §3–4. Kept as plain constants (not a design package) so every screen
/// pulls from one source instead of scattering literal values.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 4; // chips, badges
  static const double md = 8; // buttons, inputs
  static const double lg = 16; // cards, bottom sheets
  static const double full = 999; // pills, avatars, badges
}

/// Animation timing/easing tokens (Phase 6 polish) — collects every
/// previously ad-hoc `Duration(milliseconds: N)` literal scattered across
/// widgets into one named, documented source of truth. Each constant here
/// preserves its site's existing timing exactly (this is a naming/dedup
/// pass, not a re-tune), so behavior is unchanged; only [standardCurve] is
/// newly *applied* in a couple of places that previously had no explicit
/// curve (Flutter's implicit default is linear, which reads as abrupt).
class AppMotion {
  const AppMotion._();

  /// Hover/press micro-interactions (e.g. [CategoryGridCard]'s lift).
  static const Duration hoverFast = Duration(milliseconds: 150);

  /// Carousel dot indicator resize/fade.
  static const Duration carouselIndicator = Duration(milliseconds: 200);

  /// Content-swap crossfades (e.g. loading → loaded via [AnimatedSwitcher]).
  static const Duration contentSwitch = Duration(milliseconds: 250);

  /// Carousel auto-advance page slide.
  static const Duration carouselSlide = Duration(milliseconds: 500);

  /// Screen-entrance fade/slide-in (e.g. Home's initial reveal).
  static const Duration entranceFade = Duration(milliseconds: 450);

  /// Splash logo fade-in.
  static const Duration splashFade = Duration(milliseconds: 600);

  /// Splash hold after the fade completes, before navigating to Home.
  static const Duration splashHold = Duration(milliseconds: 700);

  /// Skeleton shimmer sweep (repeats, reverse: true).
  static const Duration shimmer = Duration(milliseconds: 1200);

  /// Material 3 "emphasized decelerate"-style easing — a smoother, more
  /// premium-feeling default than the implicit linear curve, used for
  /// crossfades that previously specified no curve at all.
  static const Curve standardCurve = Curves.easeOutCubic;
}

/// Icon size tiers for the handful of sizes already being reused for the
/// same purpose across unrelated screens (found via a Phase 6 audit) —
/// naming them stops future additions from re-guessing a number. Most
/// other explicit icon sizes in the app are one-off and container-fitted
/// (e.g. a banner watermark), so they're deliberately left as literals
/// rather than forced into this scale.
class AppIconSize {
  const AppIconSize._();

  /// Empty/error state illustrations.
  static const double stateIcon = 40;

  /// Large standalone feature icons (e.g. "coming soon", success states).
  static const double feature = 56;

  /// Avatar-scale icons (profile fallback, confirmation success).
  static const double avatar = 64;
}
