import 'package:flutter/material.dart';

/// Brand color tokens, per docs/DESIGN_SYSTEM.md §1.
///
/// `primary` and the two `gold` values were read directly out of the live
/// bariqon.bh production CSS (not guessed) — see DESIGN_SYSTEM.md §0 for
/// how. Neutrals/semantic colors below are Material 3 defaults, explicitly
/// flagged as placeholders pending brand confirmation.
class AppColors {
  const AppColors._();

  // --- Confirmed brand colors -----------------------------------------
  static const Color primary = Color(0xFF0F3D2E); // deep forest green
  static const Color gold = Color(0xFFD4AF37); // accent
  static const Color goldLight = Color(0xFFE4C766); // accent hover/active

  // --- Placeholder neutrals/semantics (DESIGN_SYSTEM.md §1 — unconfirmed)
  static const Color error = Color(0xFFB3261E);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF121212);
}
