import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/contact_links.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../settings/domain/site_contact_settings.dart';
import '../../../settings/presentation/controllers/site_settings_controller.dart';

/// Home screen footer, per the Phase 2B brief — brand mark, tagline,
/// contact/social icons, and a copyright line. The icons open real
/// WhatsApp/Instagram/email/phone actions via [ContactLinks] (a bug fix —
/// they previously only showed a "coming soon" snackbar), built from
/// [siteContactSettingsProvider] rather than anything hardcoded here.
class HomeFooterSection extends ConsumerWidget {
  const HomeFooterSection({super.key});

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
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(siteContactSettingsProvider);
    // Falls back to real, stable defaults while loading/on error, rather
    // than disabling the icons — see SiteContactSettings.fallback.
    final settings = settingsAsync.value ?? SiteContactSettings.fallback;

    Widget footerIcon(IconData icon, String tooltip, Uri uri) => IconButton(
      onPressed: () => _open(context, uri),
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandLogo(size: BrandLogoSize.small, padding: EdgeInsets.zero),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.homeFooterTagline,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              footerIcon(
                Icons.chat_outlined,
                l10n.contactWhatsappLabel,
                ContactLinks.whatsapp(settings),
              ),
              footerIcon(
                Icons.camera_alt_outlined,
                l10n.contactInstagramLabel,
                ContactLinks.instagram(settings),
              ),
              footerIcon(
                Icons.mail_outline,
                l10n.contactEmailLabel,
                ContactLinks.email(settings),
              ),
              footerIcon(
                Icons.call_outlined,
                l10n.contactPhoneLabel,
                ContactLinks.phone(settings),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.homeFooterRights, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
