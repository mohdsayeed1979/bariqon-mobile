import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app.dart';
import '../../../core/config/app_version_provider.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/settings_list_tile.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'controllers/settings_controller.dart';

/// Settings screen — Language (real, reuses the existing
/// [localeProvider]), Theme (real, local-only preference — see
/// [themeModeProvider]), Security, Notifications, and live app version.
/// About/Contact/Privacy/Terms live only on Profile's signed-in list now
/// (they were duplicated here before) — reachable from Profile's app bar
/// action for Guest/Signed Out sessions, which have no in-list rows of
/// their own.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(themeModeProvider);
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsThemeTitle),
        content: RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (v) => Navigator.of(context).pop(v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                title: Text(l10n.settingsThemeSystem),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                title: Text(l10n.settingsThemeLight),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                title: Text(l10n.settingsThemeDark),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      await ref.read(themeModeProvider.notifier).setThemeMode(selected);
    }
  }

  String _themeLabel(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
    ThemeMode.system => l10n.settingsThemeSystem,
    ThemeMode.light => l10n.settingsThemeLight,
    ThemeMode.dark => l10n.settingsThemeDark,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final languageLabel = locale.languageCode == 'en'
        ? l10n.settingsLanguageEnglish
        : l10n.settingsLanguageArabic;
    final packageInfo = ref.watch(packageInfoProvider);

    return Scaffold(
      appBar: BrandedAppBar(title: l10n.settingsTitle, showSearchAction: false),
      body: ResponsiveCenter(
        width: ContentWidth.wide,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: [
            SectionCard(
              children: [
                SettingsListTile(
                  icon: Icons.translate_outlined,
                  label: l10n.settingsLanguageTitle,
                  trailingText: languageLabel,
                  onTap: () {
                    ref.read(localeProvider.notifier).state =
                        locale.languageCode == 'en'
                        ? const Locale('ar')
                        : const Locale('en');
                  },
                ),
                const Divider(height: 1),
                SettingsListTile(
                  icon: Icons.dark_mode_outlined,
                  label: l10n.settingsThemeTitle,
                  trailingText: _themeLabel(l10n, themeMode),
                  onTap: () => _pickTheme(context, ref),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              children: [
                SettingsListTile(
                  icon: Icons.lock_outline,
                  label: l10n.securityTitle,
                  onTap: () => context.push('/settings/security'),
                ),
                const Divider(height: 1),
                SettingsListTile(
                  icon: Icons.notifications_outlined,
                  label: l10n.settingsNotificationsTitle,
                  onTap: () => context.push('/settings/notifications'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              children: [
                // Read live from package_info_plus (never hand-typed) —
                // no onTap, this row is informational only.
                SettingsListTile(
                  icon: Icons.info_outline,
                  label: l10n.settingsVersionLabel,
                  trailingText: packageInfo.when(
                    data: (info) => '${info.version} (${info.buildNumber})',
                    loading: () => '',
                    error: (_, _) => '',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
