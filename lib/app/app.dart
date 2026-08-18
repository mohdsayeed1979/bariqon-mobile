import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3.x moved StateProvider (and other pre-codegen providers) into
// a dedicated `legacy` import to signal the codegen-first API is now
// preferred — still fully supported, just explicit about it.
import 'package:flutter_riverpod/legacy.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/presentation/controllers/settings_controller.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_lock_gate.dart';
import 'router.dart';
import 'update_gate.dart';

/// Current app locale. Hand-written (no codegen — see Phase 1 summary),
/// seeded from [AppConfig.defaultLocale]. This is the eventual backing
/// state for the Language Selector screen (roadmap §9); Phase 1 only wires
/// the mechanism, not that screen.
final localeProvider = StateProvider<Locale>((ref) => AppConfig.defaultLocale);

/// Root widget — assembles routing, theme, and localization, per
/// docs/ARCHITECTURE.md §1/§5/§16/§17. No business feature state lives
/// here; this is app shell only.
class BariqonApp extends ConsumerWidget {
  const BariqonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final isRtl = AppConfig.isRtl(locale);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // Sits above the Navigator (router builds inside this), so both gates
      // enforce themselves regardless of which route is current rather than
      // every screen needing to check state itself. UpdateGate is outermost:
      // a mandatory Google Play update outranks even the lock screen.
      builder: (context, child) => UpdateGate(
        child: AppLockGate(child: child ?? const SizedBox.shrink()),
      ),
      theme: AppTheme.light(isRtl: isRtl),
      darkTheme: AppTheme.dark(isRtl: isRtl),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppConfig.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
