import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/notification_preferences.dart';

const _themeModePrefsKey = 'theme_mode';

/// Reads the persisted theme preference (if any) before the app first
/// renders. Called once during `bootstrap()`, before `runApp`, so the
/// correct theme is what actually paints the first frame rather than
/// flashing system default then switching.
Future<ThemeMode> loadPersistedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(_themeModePrefsKey);
  return ThemeMode.values.firstWhere(
    (mode) => mode.name == stored,
    orElse: () => ThemeMode.system,
  );
}

/// App-wide theme preference, per the Phase 4 brief's "Theme" settings
/// row — persisted to disk via [SharedPreferences] so it survives app
/// restarts, unlike the still-local-only Notifications/About rows.
/// [build]'s initial value comes from [loadPersistedThemeMode] via the
/// `ProviderScope` override installed in `bootstrap()`; this class itself
/// only needs to persist on every subsequent change.
class ThemeModeController extends Notifier<ThemeMode> {
  ThemeModeController([this._initial = ThemeMode.system]);

  final ThemeMode _initial;

  @override
  ThemeMode build() => _initial;

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModePrefsKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class NotificationPreferencesController extends Notifier<NotificationPreferences> {
  @override
  NotificationPreferences build() => const NotificationPreferences();

  void setOrderAndInquiryUpdates(bool value) {
    state = state.copyWith(orderAndInquiryUpdates: value);
  }

  void setPromotionsAndOffers(bool value) {
    state = state.copyWith(promotionsAndOffers: value);
  }

  void setNewArrivals(bool value) {
    state = state.copyWith(newArrivals: value);
  }
}

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesController, NotificationPreferences>(
      NotificationPreferencesController.new,
    );
