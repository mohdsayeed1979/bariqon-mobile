import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// See lib/app/app.dart's localeProvider comment — same rationale for using
// the pre-codegen `StateProvider` here.
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/notification_preferences.dart';

/// App-wide theme preference — local only (no persistence yet), per the
/// Phase 4 brief's "Theme" settings row. Wired into [BariqonApp]'s
/// `themeMode` so, unlike the other Phase 4 UI-only rows, this one is
/// immediately real: the same "local state now, no backend" bar every
/// other mock feature in this app already clears.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

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
