import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_preferences_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/app_lock_settings.dart';

/// App Lock settings — local-only per the Settings brief, architected so a
/// future backend-synced version only changes this controller's data
/// source, not [AppLockSettingsScreen]/[AppLockGate]. Non-secret fields
/// (enabled/method/timeout) go through [LocalPreferencesService]; the PIN
/// itself never touches this controller directly, only through
/// [SecureStorageService]'s hash-based create/verify/remove.
class AppLockController extends Notifier<AppLockSettings> {
  LocalPreferencesService get _prefs =>
      ref.read(localPreferencesServiceProvider);
  SecureStorageService get _secureStorage =>
      ref.read(secureStorageServiceProvider);

  @override
  AppLockSettings build() {
    final method = switch (_prefs.getAppLockMethod()) {
      'biometric' => AppLockMethod.biometric,
      'pin' => AppLockMethod.pin,
      _ => null,
    };
    final timeout = AppLockTimeout.values.firstWhere(
      (t) => t.duration.inSeconds == _prefs.getAppLockTimeoutSeconds(),
      orElse: () => AppLockTimeout.immediately,
    );

    // hasPin requires an async secure-storage read; start with the safe
    // default (false) and refresh it once the read completes, same
    // fire-and-forget-then-update-state shape used elsewhere in this app.
    _refreshHasPin();

    return AppLockSettings(
      enabled: _prefs.getAppLockEnabled(),
      method: method,
      timeout: timeout,
    );
  }

  Future<void> _refreshHasPin() async {
    final hasPin = await _secureStorage.hasPin();
    state = state.copyWith(hasPin: hasPin);
  }

  Future<void> enableWithBiometric() async {
    await _prefs.setAppLockEnabled(true);
    await _prefs.setAppLockMethod('biometric');
    state = state.copyWith(enabled: true, method: () => AppLockMethod.biometric);
  }

  /// Enables App Lock with PIN as the method, creating the PIN itself.
  Future<void> enableWithNewPin(String pin) async {
    await _secureStorage.setPin(pin);
    await _prefs.setAppLockEnabled(true);
    await _prefs.setAppLockMethod('pin');
    state = state.copyWith(
      enabled: true,
      method: () => AppLockMethod.pin,
      hasPin: true,
    );
  }

  Future<void> disable() async {
    await _prefs.setAppLockEnabled(false);
    state = state.copyWith(enabled: false);
  }

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    final verified = await _secureStorage.verifyPin(currentPin);
    if (!verified) return false;
    await _secureStorage.setPin(newPin);
    return true;
  }

  /// Removes the PIN outright. If PIN was the active method, App Lock
  /// falls back to disabled rather than being left in a broken
  /// "enabled with no way to unlock" state.
  Future<void> removePin() async {
    await _secureStorage.removePin();
    final wasPinMethod = state.method == AppLockMethod.pin;
    if (wasPinMethod) {
      await _prefs.setAppLockEnabled(false);
      await _prefs.setAppLockMethod(null);
    }
    state = state.copyWith(
      hasPin: false,
      enabled: wasPinMethod ? false : state.enabled,
      method: wasPinMethod ? () => null : null,
    );
  }

  Future<bool> verifyPin(String pin) => _secureStorage.verifyPin(pin);

  Future<void> setTimeout(AppLockTimeout timeout) async {
    await _prefs.setAppLockTimeoutSeconds(timeout.duration.inSeconds);
    state = state.copyWith(timeout: timeout);
  }
}

final appLockControllerProvider =
    NotifierProvider<AppLockController, AppLockSettings>(
      AppLockController.new,
    );
