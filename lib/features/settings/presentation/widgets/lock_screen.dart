import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/biometric_auth_service.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/pin_input_field.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/app_lock_settings.dart';
import '../controllers/app_lock_controller.dart';

/// Full-screen App Lock challenge — shown by [AppLockGate] over the whole
/// app (any route) when locked. Biometric method auto-prompts on show;
/// PIN method shows a numeric field, verified against the hash in
/// [SecureStorageService].
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({
    super.key,
    required this.onUnlocked,
    required this.onAuthenticatingChanged,
  });

  final VoidCallback onUnlocked;

  /// Tells [AppLockGate] when a biometric prompt is in flight, so it can
  /// ignore the lifecycle churn the prompt itself causes — see
  /// `AppLockGate._authenticating`'s doc comment for why this exists.
  final ValueChanged<bool> onAuthenticatingChanged;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pinController = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _autoPromptedBiometric = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    widget.onAuthenticatingChanged(true);
    bool success = false;
    try {
      success = await ref
          .read(biometricAuthServiceProvider)
          .authenticate(l10n.biometricUnlockPromptReason);
    } finally {
      widget.onAuthenticatingChanged(false);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) widget.onUnlocked();
  }

  Future<void> _submitPin() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final verified = await ref
        .read(appLockControllerProvider.notifier)
        .verifyPin(_pinController.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (verified) {
      widget.onUnlocked();
    } else {
      _pinController.clear();
      setState(() => _error = l10n.pinIncorrectError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final method = ref.watch(appLockControllerProvider).method;

    if (method == AppLockMethod.biometric && !_autoPromptedBiometric) {
      _autoPromptedBiometric = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(size: BrandLogoSize.small),
                  const SizedBox(height: 16),
                  Text(
                    l10n.lockScreenTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (method == AppLockMethod.pin) ...[
                    PinInputField(
                      controller: _pinController,
                      label: l10n.pinCurrentLabel,
                      autofocus: true,
                      errorText: _error,
                      onChanged: (_) => setState(() => _error = null),
                      onSubmitted: (_) => _busy ? null : _submitPin(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _submitPin,
                        child: _busy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.lockScreenUnlockCta),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _tryBiometric,
                        icon: const Icon(Icons.fingerprint),
                        label: Text(l10n.lockScreenUnlockCta),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
