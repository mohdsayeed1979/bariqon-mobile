import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_preferences_service.dart';
import '../../domain/notification_preferences.dart';

/// App-wide theme preference, per the Phase 4 brief's "Theme" settings
/// row — persisted via [LocalPreferencesService] (a bug fix: it used to
/// reset to System on every restart) and restored synchronously on
/// startup, since `SharedPreferences` is already fully loaded into memory
/// by the time this `build()` runs (see bootstrap.dart). Defaults to
/// System only when nothing has ever been explicitly saved — never resets
/// to it after an explicit choice.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ref.watch(localPreferencesServiceProvider).getThemeMode() ??
        ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    ref.read(localPreferencesServiceProvider).setThemeMode(mode);
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
