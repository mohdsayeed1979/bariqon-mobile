import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/contact_links.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/site_contact_settings.dart';
import 'controllers/site_settings_controller.dart';

/// Contact Us screen — real contact details from
/// [siteContactSettingsProvider] (the CMS's `cms_site_settings` table),
/// the same source the Home footer uses, so there is exactly one place
/// this data comes from. Each row is tappable via [ContactLinks] — this
/// screen previously showed hardcoded, display-only static text.
class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    final l10n = AppLocalizations.of(context);
    final opened = await ContactLinks.launch(uri);
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.contactLinkFailedMessage)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final settingsAsync = ref.watch(siteContactSettingsProvider);
    final settings = settingsAsync.value ?? SiteContactSettings.fallback;

    return Scaffold(
      appBar: BrandedAppBar(
        title: l10n.settingsContactTitle,
        showSearchAction: false,
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          width: ContentWidth.wide,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(l10n.contactEmailLabel),
                subtitle: Text(settings.emailAddress),
                onTap: () => _open(context, ContactLinks.email(settings)),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text(l10n.contactPhoneLabel),
                subtitle: Text(settings.phoneNumber),
                onTap: () => _open(context, ContactLinks.phone(settings)),
              ),
              ListTile(
                leading: const Icon(Icons.chat_outlined),
                title: Text(l10n.contactWhatsappLabel),
                subtitle: Text(settings.phoneNumber),
                onTap: () => _open(context, ContactLinks.whatsapp(settings)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(l10n.contactInstagramLabel),
                subtitle: const Text('@bariqon.bahrain'),
                onTap: () => _open(context, ContactLinks.instagram(settings)),
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(l10n.contactAddressLabel),
                subtitle: Text(settings.address(locale)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
