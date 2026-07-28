/// Brand font families, per docs/DESIGN_SYSTEM.md §2 — confirmed from the
/// live site's `@font-face` declarations, not guessed.
///
/// NOTE: the actual font asset files (.ttf/.otf) are not bundled yet. That's
/// an asset-organization step (docs/IMPLEMENTATION_ROADMAP.md §20) requiring
/// downloading font binaries, which needs your explicit go-ahead before any
/// file is fetched. Until then, these family names are wired into the theme
/// but Flutter will silently fall back to the platform default font — no
/// crash, just not-yet-branded typography. Swapping in the real files later
/// is a pubspec.yaml + assets/fonts/ change only; nothing here needs to
/// change.
class AppFonts {
  const AppFonts._();

  // LTR (English)
  static const String bodyLtr = 'Inter';
  static const String headingLtr = 'PlayfairDisplay';

  // RTL (Arabic) — confirmed as a *different* serif for headings (Amiri),
  // not just a glyph fallback of Playfair Display.
  static const String bodyRtl = 'Cairo';
  static const String headingRtl = 'Amiri';
}
