import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in bootstrap.dart with the real, already-loaded
/// `SharedPreferences` instance (`SharedPreferences.getInstance()` is
/// awaited once, before `runApp`). Defaults to null rather than throwing
/// when not overridden — true for every `flutter test` run today, since
/// tests pump the app directly without going through `bootstrap()`.
/// [LocalPreferencesService] treats a null instance as "nothing persisted
/// yet" rather than crashing, so App Lock settings fall back to their
/// in-memory defaults during tests instead of needing every test rewired.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Single access point for non-secret local preferences: App Lock's
/// enabled/method/timeout (the PIN itself never lives here, see
/// [SecureStorageService]), and the theme mode preference.
class LocalPreferencesService {
  LocalPreferencesService(this._prefs);

  final SharedPreferences? _prefs;

  static const _appLockEnabledKey = 'app_lock_enabled';
  static const _appLockMethodKey = 'app_lock_method';
  static const _appLockTimeoutKey = 'app_lock_timeout';
  static const _themeModeKey = 'theme_mode';

  /// Null means nothing persisted yet — the caller falls back to
  /// [ThemeMode.system], not this service's concern to decide that
  /// default.
  ThemeMode? getThemeMode() => switch (_prefs?.getString(_themeModeKey)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => null,
  };

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs?.setString(_themeModeKey, mode.name);
  }

  bool getAppLockEnabled() => _prefs?.getBool(_appLockEnabledKey) ?? false;

  Future<void> setAppLockEnabled(bool value) async {
    await _prefs?.setBool(_appLockEnabledKey, value);
  }

  /// 'biometric' or 'pin' — null means no method chosen yet.
  String? getAppLockMethod() => _prefs?.getString(_appLockMethodKey);

  Future<void> setAppLockMethod(String? method) async {
    if (method == null) {
      await _prefs?.remove(_appLockMethodKey);
    } else {
      await _prefs?.setString(_appLockMethodKey, method);
    }
  }

  /// Seconds; 0 = "Immediately". Defaults to 0 (immediately) when unset —
  /// the safest default for a security feature the user just turned on.
  int getAppLockTimeoutSeconds() => _prefs?.getInt(_appLockTimeoutKey) ?? 0;

  Future<void> setAppLockTimeoutSeconds(int seconds) async {
    await _prefs?.setInt(_appLockTimeoutKey, seconds);
  }
}

final localPreferencesServiceProvider = Provider<LocalPreferencesService>((
  ref,
) {
  return LocalPreferencesService(ref.watch(sharedPreferencesProvider));
});
