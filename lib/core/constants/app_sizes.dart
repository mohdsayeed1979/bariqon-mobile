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
