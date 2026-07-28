import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Contact Us screen, per the Phase 4 brief — display-only contact
/// details (no url_launcher/tel/mailto wiring; that's a real-integration
/// concern for later, not part of this UI-only phase).
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const String _email = 'info@bariqon.bh';
  static const String _phone = '+973 1700 0000';
  static const String _whatsapp = '+973 3300 0000';
  static const String _address = 'Manama, Kingdom of Bahrain';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: BrandedAppBar(
        title: l10n.settingsContactTitle,
        showSearchAction: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: Text(l10n.contactEmailLabel),
              subtitle: const Text(_email),
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(l10n.contactPhoneLabel),
              subtitle: const Text(_phone),
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: Text(l10n.contactWhatsappLabel),
              subtitle: const Text(_whatsapp),
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(l10n.contactAddressLabel),
              subtitle: const Text(_address),
            ),
          ],
        ),
      ),
    );
  }
}
