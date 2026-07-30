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

  // --- True-neutral surface container tones (Phase 6 fix) --------------
  // `ColorScheme.fromSeed` derives surfaceContainer*/outline tones from
  // the seed color's hue by design — with `primary` as a deep, saturated
  // forest green, that made every card/footer/search-bar/summary surface
  // that reads `colorScheme.surfaceContainerHighest` come out muted and
  // greenish rather than a clean neutral, which is almost certainly what
  // read as "the UI feels slightly darker than desired." These are true
  // grays (no green cast) passed as explicit overrides in app_theme.dart,
  // so the confirmed brand primary/gold themselves are untouched — only
  // the *derived* neutral tones change.
  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowLight = Color(0xFFF7F7F5);
  static const Color surfaceContainerLight = Color(0xFFF1F1EF);
  static const Color surfaceContainerHighLight = Color(0xFFEBEBE8);
  static const Color surfaceContainerHighestLight = Color(0xFFE4E4E1);
  static const Color outlineLight = Color(0xFF79766F);
  static const Color outlineVariantLight = Color(0xFFC9C7C0);

  static const Color surfaceContainerLowestDark = Color(0xFF0B0B0B);
  static const Color surfaceContainerLowDark = Color(0xFF191919);
  static const Color surfaceContainerDark = Color(0xFF1E1E1E);
  static const Color surfaceContainerHighDark = Color(0xFF282828);
  static const Color surfaceContainerHighestDark = Color(0xFF333333);
  static const Color outlineDark = Color(0xFF93918A);
  static const Color outlineVariantDark = Color(0xFF444440);
}
