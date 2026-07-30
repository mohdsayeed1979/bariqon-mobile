import 'package:flutter/material.dart';

import 'app_fonts.dart';

/// Builds a [TextTheme] using the confirmed brand font pair for the given
/// writing direction — body/heading fonts genuinely differ by direction
/// (see AppFonts), not just by glyph-set fallback, so this takes [isRtl]
/// rather than assuming one font family covers both locales.
TextTheme buildAppTextTheme({required Color color, required bool isRtl}) {
  final String bodyFont = isRtl ? AppFonts.bodyRtl : AppFonts.bodyLtr;
  final String headingFont = isRtl ? AppFonts.headingRtl : AppFonts.headingLtr;

  TextStyle heading(double size, FontWeight weight) => TextStyle(
    fontFamily: headingFont,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: 0.4, // mirrors the site's heading letter-spacing
  );

  TextStyle body(double size, FontWeight weight, {double? height}) =>
      TextStyle(
        fontFamily: bodyFont,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  return TextTheme(
    displayLarge: heading(57, FontWeight.w700),
    displayMedium: heading(45, FontWeight.w700),
    displaySmall: heading(36, FontWeight.w600),
    headlineLarge: heading(32, FontWeight.w600),
    headlineMedium: heading(28, FontWeight.w600),
    headlineSmall: heading(24, FontWeight.w600),
    titleLarge: heading(22, FontWeight.w600),
    titleMedium: body(16, FontWeight.w600),
    titleSmall: body(14, FontWeight.w600),
    // Reading copy (descriptions, messages, form hints) gets a slightly
    // taller line height for a calmer, more premium reading feel — UI
    // chrome (titles/labels above/below) stays at the tighter default so
    // this doesn't inflate button/tile heights across the app.
    bodyLarge: body(16, FontWeight.w400, height: 1.5),
    bodyMedium: body(14, FontWeight.w400, height: 1.5),
    bodySmall: body(12, FontWeight.w400, height: 1.4),
    labelLarge: body(14, FontWeight.w600),
    labelMedium: body(12, FontWeight.w600),
    labelSmall: body(11, FontWeight.w600),
  );
}
