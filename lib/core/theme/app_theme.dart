import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_theme.dart';

/// Assembles the app's light/dark [ThemeData] from the brand tokens in
/// [AppColors], per docs/DESIGN_SYSTEM.md. Text direction affects font
/// selection (see app_text_theme.dart), so callers pass [isRtl] rather than
/// this being decided implicitly.
class AppTheme {
  const AppTheme._();

  static ThemeData light({required bool isRtl}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.gold,
      tertiary: AppColors.goldLight,
      error: AppColors.error,
      surface: AppColors.surfaceLight,
    );

    return _base(colorScheme: colorScheme, isRtl: isRtl);
  }

  static ThemeData dark({required bool isRtl}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.gold,
      tertiary: AppColors.goldLight,
      error: AppColors.error,
      surface: AppColors.surfaceDark,
    );

    return _base(colorScheme: colorScheme, isRtl: isRtl);
  }

  static ThemeData _base({
    required ColorScheme colorScheme,
    required bool isRtl,
  }) {
    final textTheme = buildAppTextTheme(
      color: colorScheme.onSurface,
      isRtl: isRtl,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      // Was missing entirely — every FilledButton/FilledButton.tonal (the
      // primary CTA on most forms) fell back to Material 3's 40dp default
      // minimum height unless a screen manually wrapped it in a
      // fixed-height SizedBox, which not all of them did (e.g. Profile's
      // "Edit Profile"/"Sign Out" buttons) — under the 48dp accessible
      // tap-target guideline. `minimumSize` (not a fixed size) still lets
      // the button grow taller if a translation or larger text-scale
      // setting needs more room, unlike a hard-coded SizedBox height.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // Material 3 navigation components — used by AppShell (bottom nav on
      // phones, NavigationRail on wide layouts), per docs/DESIGN_SYSTEM.md
      // §8's bottom-nav spec: active item tinted primary, inactive neutral.
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
