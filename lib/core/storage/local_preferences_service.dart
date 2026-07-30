import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in bootstrap.dart with the real, already-loaded
/// `SharedPreferences` instance (`SharedPreferences.getInstance()` is
/// awaited once, before `runApp`, same as `Supabase.initialize`). Defaults
/// to null rather than throwing when not overridden — true for every
/// `flutter test` run today, since tests pump `BariqonApp` directly
/// without going through `bootstrap()`. [LocalPreferencesService] treats a
/// null instance as "nothing persisted yet" rather than crashing, so
/// theme/App Lock/remember-me settings all just fall back to their
/// in-memory defaults during tests instead of needing every test rewired.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Single access point for non-secret local preferences (theme,
/// remember-me, App Lock settings) — per the `SupabaseService`/
/// `sharedPreferencesProvider` "one wrapper, nothing else touches the
/// plugin directly" shape already established in this codebase. The PIN
/// itself never lives here — see `SecureStorageService` for that.
class LocalPreferencesService {
  LocalPreferencesService(this._prefs);

  final SharedPreferences? _prefs;

  static const _themeModeKey = 'theme_mode';
  static const _rememberMeKey = 'auth_remember_me';
  static const _appLockEnabledKey = 'app_lock_enabled';
  static const _appLockMethodKey = 'app_lock_method';
  static const _appLockTimeoutKey = 'app_lock_timeout';
  static const _profileExtraPrefix = 'profile_extra_';

  ThemeMode? getThemeMode() => switch (_prefs?.getString(_themeModeKey)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => null,
  };

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs?.setString(_themeModeKey, mode.name);
  }

  /// Defaults to `true` (persist the session) when nothing has been saved
  /// yet — matches how every other auth-adjacent app behaves out of the
  /// box, and how this app's own Remember Me checkbox starts unchecked
  /// only because the *user* hasn't logged in yet, not because "don't
  /// remember me" is the intended default once they do.
  bool getRememberMe() => _prefs?.getBool(_rememberMeKey) ?? true;

  Future<void> setRememberMe(bool value) async {
    await _prefs?.setBool(_rememberMeKey, value);
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

  /// Company/Mobile/Country are collected by Registration/Edit Profile but
  /// have no column in the real `profiles` table (confirmed schema: id,
  /// email, full_name, created_at, updated_at only — see
  /// docs/BACKEND_MAPPING_REPORT.md) — rather than inventing a schema
  /// change or silently dropping the fields, they're kept device-local,
  /// keyed by user id, per an explicit product decision. Not synced across
  /// devices or visible to the backend/website — a fresh install or a
  /// different device simply won't have them until the schema grows to
  /// hold them for real.
  Map<String, String> getProfileExtra(String userId) {
    final raw = _prefs?.getString('$_profileExtraPrefix$userId');
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as String));
    } catch (_) {
      return const {};
    }
  }

  Future<void> setProfileExtra(
    String userId, {
    required String company,
    required String mobile,
    required String country,
  }) async {
    await _prefs?.setString(
      '$_profileExtraPrefix$userId',
      jsonEncode({'company': company, 'mobile': mobile, 'country': country}),
    );
  }
}

final localPreferencesServiceProvider = Provider<LocalPreferencesService>((
  ref,
) {
  return LocalPreferencesService(ref.watch(sharedPreferencesProvider));
});
