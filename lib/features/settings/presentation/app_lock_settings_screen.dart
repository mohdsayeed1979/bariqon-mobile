import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/biometric_auth_service.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/settings_list_tile.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/app_lock_settings.dart';
import 'controllers/app_lock_controller.dart';
import 'widgets/pin_dialogs.dart';

/// Security settings screen ("App Lock") — enable/disable, choose
/// Biometric or PIN, PIN create/change/remove, and lock timeout. Local
/// only, per the brief: [AppLockController] persists through
/// [LocalPreferencesService]/[SecureStorageService], no backend call
/// anywhere on this screen.
class AppLockSettingsScreen extends ConsumerWidget {
  const AppLockSettingsScreen({super.key});

  Future<void> _showSnack(BuildContext context, String message) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _manageCreateOrChangePin(
    BuildContext context,
    WidgetRef ref,
    AppLockSettings settings,
  ) async {
    final l10n = AppLocalizations.of(context);
    final bool ok;
    if (settings.hasPin) {
      ok = await showChangePinDialog(context, ref);
    } else {
      ok = await showCreatePinDialog(context, ref);
    }
    if (!context.mounted || !ok) return;
    await _showSnack(
      context,
      settings.hasPin ? l10n.pinChangedSuccess : l10n.pinCreatedSuccess,
    );
  }

  Future<void> _manageRemovePin(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showRemovePinDialog(context, ref);
    if (!context.mounted || !ok) return;
    await _showSnack(context, l10n.pinRemovedSuccess);
  }

  Future<void> _onToggleEnabled(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final controller = ref.read(appLockControllerProvider.notifier);
    if (!value) {
      await controller.disable();
      return;
    }
    await _chooseMethod(context, ref);
  }

  /// Shared by the initial "turn App Lock on" flow and the "Authentication
  /// Method" row's "change method" flow.
  Future<void> _chooseMethod(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final method = await showDialog<AppLockMethod>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.appLockChooseMethodTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(AppLockMethod.biometric),
            child: Row(
              children: [
                const Icon(Icons.fingerprint),
                const SizedBox(width: 12),
                // Flexible: Arabic's translated label runs longer than
                // English here, and this Row has no other flexible child
                // to absorb that — the same overflow shape flagged
                // throughout this app since Phase 2B.
                Flexible(
                  child: Text(
                    l10n.appLockMethodBiometric,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(AppLockMethod.pin),
            child: Row(
              children: [
                const Icon(Icons.pin_outlined),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    l10n.appLockMethodPin,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (method == null || !context.mounted) return;

    if (method == AppLockMethod.biometric) {
      final biometrics = ref.read(biometricAuthServiceProvider);
      final supported = await biometrics.isSupported();
      if (!context.mounted) return;
      if (!supported) {
        await _showSnack(context, l10n.biometricUnavailableMessage);
        return;
      }
      final authenticated = await biometrics.authenticate(
        l10n.biometricEnablePromptReason,
      );
      if (!context.mounted) return;
      if (!authenticated) return;
      await ref.read(appLockControllerProvider.notifier).enableWithBiometric();
    } else {
      final created = await showCreatePinDialog(context, ref);
      if (!context.mounted || !created) return;
      await _showSnack(context, l10n.pinCreatedSuccess);
    }
  }

  Future<void> _pickTimeout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(appLockControllerProvider).timeout;
    final selected = await showDialog<AppLockTimeout>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.appLockTimeoutTitle),
        content: RadioGroup<AppLockTimeout>(
          groupValue: current,
          onChanged: (v) => Navigator.of(context).pop(v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<AppLockTimeout>(
                value: AppLockTimeout.immediately,
                title: Text(l10n.appLockTimeoutImmediately),
              ),
              RadioListTile<AppLockTimeout>(
                value: AppLockTimeout.oneMinute,
                title: Text(l10n.appLockTimeoutOneMinute),
              ),
              RadioListTile<AppLockTimeout>(
                value: AppLockTimeout.fiveMinutes,
                title: Text(l10n.appLockTimeoutFiveMinutes),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      await ref.read(appLockControllerProvider.notifier).setTimeout(selected);
    }
  }

  String _timeoutLabel(AppLocalizations l10n, AppLockTimeout timeout) =>
      switch (timeout) {
        AppLockTimeout.immediately => l10n.appLockTimeoutImmediately,
        AppLockTimeout.oneMinute => l10n.appLockTimeoutOneMinute,
        AppLockTimeout.fiveMinutes => l10n.appLockTimeoutFiveMinutes,
      };

  String _methodLabel(AppLocalizations l10n, AppLockMethod? method) =>
      switch (method) {
        AppLockMethod.biometric => l10n.appLockMethodBiometric,
        AppLockMethod.pin => l10n.appLockMethodPin,
        null => l10n.appLockMethodNone,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appLockControllerProvider);

    return Scaffold(
      appBar: BrandedAppBar(title: l10n.securityTitle, showSearchAction: false),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              l10n.appLockDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SwitchListTile(
            value: settings.enabled,
            onChanged: (value) => _onToggleEnabled(context, ref, value),
            title: Text(l10n.appLockEnableRow),
          ),
          if (settings.enabled) ...[
            const Divider(height: 1),
            SettingsListTile(
              icon: Icons.security_outlined,
              label: l10n.appLockMethodTitle,
              trailingText: _methodLabel(l10n, settings.method),
              onTap: () => _chooseMethod(context, ref),
            ),
            if (settings.method == AppLockMethod.pin) ...[
              const Divider(height: 1),
              SettingsListTile(
                icon: Icons.password_outlined,
                label: settings.hasPin
                    ? l10n.pinManagementChangeTitle
                    : l10n.pinManagementCreateTitle,
                onTap: () => _manageCreateOrChangePin(context, ref, settings),
              ),
              if (settings.hasPin) ...[
                const Divider(height: 1),
                SettingsListTile(
                  icon: Icons.delete_outline,
                  label: l10n.pinManagementRemoveTitle,
                  onTap: () => _manageRemovePin(context, ref),
                ),
              ],
            ],
            const Divider(height: 1),
            SettingsListTile(
              icon: Icons.timer_outlined,
              label: l10n.appLockTimeoutTitle,
              trailingText: _timeoutLabel(l10n, settings.timeout),
              onTap: () => _pickTimeout(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}
