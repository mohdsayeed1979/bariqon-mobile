import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../l10n/generated/app_localizations.dart';

/// The single reusable branded app bar, per the Phase 2A brief — every
/// screen that needs an app bar (the four tab roots today, more screens in
/// later phases) should use this rather than building its own `AppBar`, so
/// title styling and the search entry point stay consistent everywhere.
///
/// Standard [AppBar] underneath (not a bespoke layout), so back-button
/// handling, safe areas, etc. all come for free.
class BrandedAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const BrandedAppBar({super.key, required this.title, this.showSearchAction = true});

  final String title;

  /// Whether the search icon (→ the Phase 2A search UI shell) is shown.
  /// Off for screens that don't make sense to search from (e.g. the search
  /// screen itself, once it exists).
  final bool showSearchAction;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);

    return AppBar(
      title: Text(title),
      actions: [
        if (showSearchAction)
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.searchTitle,
            onPressed: () => context.push('/search'),
          ),
        // Temporary: lets EN/AR be verified from any screen ahead of the
        // real Language Selector (Settings, Phase 2B). Remove once that
        // screen exists — see docs/IMPLEMENTATION_ROADMAP.md §9.
        IconButton(
          icon: const Icon(Icons.language),
          tooltip: l10n.toggleLanguageTooltip,
          onPressed: () {
            ref.read(localeProvider.notifier).state = locale.languageCode == 'en'
                ? const Locale('ar')
                : const Locale('en');
          },
        ),
      ],
    );
  }
}
