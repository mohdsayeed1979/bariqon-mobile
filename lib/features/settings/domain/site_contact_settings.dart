import 'package:flutter/widgets.dart';

/// Real business contact/social details, sourced from the CMS's
/// `cms_site_settings` key-value table (confirmed schema — `key`/`value`
/// rows, not columns) — used by both the Home footer and the Contact
/// screen, so there is exactly one place these values are read from,
/// never hardcoded per-screen.
class SiteContactSettings {
  const SiteContactSettings({
    required this.phoneNumber,
    required this.whatsappNumber,
    required this.emailAddress,
    required this.instagramUrl,
    required this.addressEn,
    required this.addressAr,
  });

  final String phoneNumber;

  /// Digits only (no `+`, spaces, or dashes) — the format `wa.me` expects,
  /// and how `cms_site_settings.whatsapp_number` is actually stored.
  final String whatsappNumber;
  final String emailAddress;
  final String instagramUrl;
  final String addressEn;
  final String addressAr;

  /// The real, confirmed values (per docs/BACKEND_MAPPING_REPORT.md's
  /// follow-up query) — used as both the mock repository's data and each
  /// field's defensive fallback in the Supabase repository, so a
  /// temporarily-missing CMS key degrades to real company info instead of
  /// a placeholder string.
  static const fallback = SiteContactSettings(
    phoneNumber: '+973 3362 1109',
    whatsappNumber: '97333621109',
    emailAddress: 'info@bariqon.bh',
    instagramUrl: 'https://www.instagram.com/bariqon.bahrain',
    addressEn: 'Manama, Kingdom of Bahrain',
    addressAr: 'المنامة، مملكة البحرين',
  );

  String address(Locale locale) =>
      locale.languageCode == 'ar' ? addressAr : addressEn;
}
