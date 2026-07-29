import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'controllers/settings_controller.dart';

/// Notification Preferences screen, per the Phase 4 brief — UI only, no
/// push-notification wiring. Local Riverpod state ([notificationPreferencesProvider])
/// so the toggles are real within the session, just not persisted or acted on yet.
class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);

    return Scaffold(
      appBar: BrandedAppBar(
        title: l10n.settingsNotificationsTitle,
        showSearchAction: false,
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          width: ContentWidth.wide,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              SwitchListTile(
                value: prefs.orderAndInquiryUpdates,
                onChanged: notifier.setOrderAndInquiryUpdates,
                title: Text(l10n.notificationOrderUpdatesTitle),
                subtitle: Text(l10n.notificationOrderUpdatesSubtitle),
              ),
              SwitchListTile(
                value: prefs.promotionsAndOffers,
                onChanged: notifier.setPromotionsAndOffers,
                title: Text(l10n.notificationPromotionsTitle),
                subtitle: Text(l10n.notificationPromotionsSubtitle),
              ),
              SwitchListTile(
                value: prefs.newArrivals,
                onChanged: notifier.setNewArrivals,
                title: Text(l10n.notificationNewArrivalsTitle),
                subtitle: Text(l10n.notificationNewArrivalsSubtitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
