import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_preferences_service.dart';
import '../../domain/notification_preferences.dart';

/// App-wide theme preference, persisted via [LocalPreferencesService] so
/// a choice survives an app restart — previously a plain in-memory
/// `StateProvider` that silently reset to [ThemeMode.system] (which
/// resolves to Dark on a device with system dark mode on) every cold
/// start regardless of what the user picked. [build] reads whatever was
/// last saved (falling back to `system` if nothing was ever saved), and
/// [setThemeMode] both updates state and persists the change.
class ThemeModeController extends Notifier<ThemeMode> {
  LocalPreferencesService get _prefs => ref.read(localPreferencesServiceProvider);

  @override
  ThemeMode build() => _prefs.getThemeMode() ?? ThemeMode.system;

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setThemeMode(mode);
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
